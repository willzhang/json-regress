#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_dir="${JSON_REGRESS_MOON_HOME:-}"
if [[ -z "$runtime_dir" && -f "$project_dir/.moon-home" ]]; then
  IFS= read -r runtime_dir < "$project_dir/.moon-home" || [[ -n "$runtime_dir" ]]
fi
if [[ -n "$runtime_dir" ]]; then
  if [[ ! -x "$runtime_dir/bin/moon" ]]; then
    echo 'Configured MoonBit toolchain is unavailable; check JSON_REGRESS_MOON_HOME or .moon-home.' >&2
    exit 1
  fi
  export MOON_HOME="$runtime_dir"
  export PATH="$runtime_dir/bin:$PATH"
elif ! command -v moon >/dev/null 2>&1; then
  echo 'Install MoonBit or configure JSON_REGRESS_MOON_HOME (see README).' >&2
  exit 1
fi
cd -- "$project_dir"
exec moon "$@"
