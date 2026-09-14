#!/usr/bin/env python3
"""Fetch the pinned public source only. Never change an existing checkout."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
pin = json.loads((root / "integrations/moonxi/upstream.json").read_text())
checkout = root / ".external/moonxi-net"

def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()

if not checkout.exists():
    checkout.mkdir(parents=True)
    subprocess.run(["git", "init", str(checkout)], check=True)
    subprocess.run(["git", "-C", str(checkout), "remote", "add", "origin", pin["repository"]], check=True)
    subprocess.run(["git", "-C", str(checkout), "fetch", "--depth", "1", "origin", pin["commit"]], check=True)
    subprocess.run(["git", "-C", str(checkout), "checkout", "--detach", "FETCH_HEAD"], check=True)
if git("-C", str(checkout), "rev-parse", "HEAD") != pin["commit"]:
    raise SystemExit("Existing MoonXi checkout differs from pinned commit; left untouched.")
if git("-C", str(checkout), "status", "--porcelain"):
    raise SystemExit("MoonXi source contains edits or untracked files; left untouched.")
print(f"Verified MoonXi-net {pin['commit']} ({pin['license']}); no source edits.")
