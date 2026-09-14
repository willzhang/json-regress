#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$project_dir/scripts/moon-local.sh" -C cli build main --target native --deny-warn >&2
binary="$project_dir/cli/_build/native/debug/build/local/json_regress_cli/main/main.exe"
if [[ ! -x "$binary" ]]; then
  echo "CLI artifact not found at expected MoonBit build path: $binary" >&2
  exit 2
fi
printf '%s\n' "$binary"
