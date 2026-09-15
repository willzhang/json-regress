#!/usr/bin/env python3
"""Check staged files, reachable history, or a distribution ZIP without printing values."""
import argparse
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    "personal home path": re.compile("/" + r"Users/[^\s\"'`<>]+|[A-Za-z]:\\Users\\[^\s\"']+"),
    "machine session path": re.compile("/" + r"(?:private/)?var/folders/[^\s\"'`<>]+"),
    "machine toolchain path": re.compile("/" + r"private/tmp/moonbit-[^\s\"'`<>]+"),
    "private key": re.compile(r"-----BEGIN (?:[A-Z0-9 ]+ )?PRIVATE KEY-----"),
    "access token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}|sk-(?:proj-|ant-)?[A-Za-z0-9_-]{24,}|AKIA[0-9A-Z]{16})\b"),
    "URL credentials": re.compile(r"https?://[^\s/:]+:[^\s/@]+@"),
}
EMAIL = re.compile(r"(?<![\w.+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}(?![\w.-])")
PLANNING = re.compile(r"人工.{0,25}(?:投入|工时|预算)|奖金|季度奖|获奖概率|确定性收益")
PRIVATE_NAMES = {".moon-home", "credentials.json", "id_rsa", "id_ed25519", ".netrc", ".DS_Store"}
PRIVATE_DIRS = {".git", ".external", ".mooncakes", "artifacts", "_build", ".ssh"}
ARCHIVE_DOCS = {"AGENTS.md", "CONTRIBUTING.md", "docs/PROPOSAL_REFERENCE.md", "docs/PUBLICATION.md", "docs/GIT_HANDOFF.md", "docs/DEVELOPMENT_HISTORY.md", "docs/COMPETITIVE_REVIEW-2026-09-15.md"}

def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])

def findings(name, data, archive=False):
    path = Path(name)
    if (path.name in PRIVATE_NAMES or path.name.startswith('.env') and path.name != '.env.example'
            or set(path.parts) & PRIVATE_DIRS or path.suffix in {'.pem', '.p12', '.pfx', '.key'}):
        yield 0, "private file"
    if archive and (name in ARCHIVE_DOCS or name.startswith('docs/codex/')):
        yield 0, "repository-only document"
    for number, line in enumerate(data.decode('utf-8', errors='replace').splitlines(), 1):
        for label, pattern in PATTERNS.items():
            if pattern.search(line):
                yield number, label
        if any(not m.group().endswith(('@users.noreply.github.com', '@example.com', '@example.org')) for m in EMAIL.finditer(line)):
            yield number, "non-example contact email"
        if name.endswith('.md') and PLANNING.search(line):
            yield number, "private planning text"

def entries(args):
    if args.archive:
        with zipfile.ZipFile(args.archive) as z:
            for name in z.namelist():
                if not name.endswith('/'):
                    yield name, z.read(name)
    elif args.history:
        objects = git('rev-list', '--objects', args.ref).decode().splitlines()
        for entry in objects:
            oid, _, name = entry.partition(' ')
            kind = git('cat-file', '-t', oid).strip()
            if kind == b'blob':
                yield name, git('cat-file', 'blob', oid)
            elif kind == b'commit':
                yield 'commit:' + oid, git('cat-file', 'commit', oid)
    elif args.staged:
        for entry in git('ls-files', '-s', '-z').split(b'\0'):
            if entry:
                info, name = entry.split(b'\t', 1)
                _, oid, stage = info.decode().split()
                if stage != '0':
                    raise SystemExit('Resolve merge conflicts before checking publication.')
                yield name.decode(), git('cat-file', 'blob', oid)
    else:
        for name in git('ls-files', '-z').decode().split('\0'):
            if name and (ROOT/name).exists():
                path = ROOT/name
                yield name, str(path.readlink()).encode() if path.is_symlink() else path.read_bytes()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--archive', type=Path)
    group.add_argument('--history', action='store_true')
    group.add_argument('--staged', action='store_true')
    parser.add_argument('--ref', default='HEAD')
    args = parser.parse_args()
    count = errors = 0
    for name, data in entries(args):
        count += 1
        for line, label in findings(name, data, archive=bool(args.archive)):
            print(f'{name}:{line}: {label}; value omitted')
            errors += 1
    print(f'Publication check: {count} entries, {errors} findings.')
    raise SystemExit(bool(errors))

if __name__ == '__main__':
    main()
