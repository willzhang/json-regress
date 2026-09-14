#!/usr/bin/env python3
"""Release-time lower bound; semantic value still needs human review."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
def git(*args, **kwargs):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, **kwargs)

if git("rev-parse", "--is-shallow-repository").stdout.strip() == "true":
    raise SystemExit("Cannot audit a shallow checkout. Fetch the complete development history first.")
history = git("rev-list", "--reverse", "--no-merges", "HEAD")
commits = history.stdout.splitlines() if history.returncode == 0 else []
effective = []
for commit in commits:
    changed = git("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", commit, check=True).stdout.strip()
    if changed:
        effective.append(commit)
        print(git("show", "-s", "--format=%h %s", commit, check=True).stdout.strip())
print(f"Non-empty, non-merge commits: {len(effective)} / required minimum 10")
print("Local tree snapshots are not commits. Review each listed change for actual development value.")
if len(effective) < 10:
    raise SystemExit(1)
