#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_dir"
if [[ $# -gt 1 || (${1:-} != '' && ${1:-} != '--integration') ]]; then
  echo 'Usage: bash scripts/check-local.sh [--integration]' >&2
  exit 2
fi
moon_cmd() { bash scripts/moon-local.sh "$@"; }
python3 scripts/generate-references.py --check
moon_cmd fmt --check
moon_cmd check --deny-warn
moon_cmd build --deny-warn
moon_cmd test --deny-warn
moon_cmd test --target native --deny-warn
moon_cmd run cmd/main
moon_cmd run cmd/rl
if [[ ${1:-} == '--integration' ]]; then
  python3 scripts/fetch-moonxi.py
  moon_cmd -C integrations/moonxi fmt --check . cmd/showcases
  mkdir -p artifacts
  integration_log="$project_dir/artifacts/moonxi-validation.log"
  if ! (
    set -e
    moon_cmd -C integrations/moonxi check . cmd/showcases --target native
    moon_cmd -C integrations/moonxi test -p local/json_regress_moonxi --target native
    moon_cmd -C integrations/moonxi run cmd/showcases --target native
  ) > "$integration_log" 2>&1; then
    cat "$integration_log" >&2
    exit 1
  fi
  tail -n 9 "$integration_log"
  python3 scripts/fetch-moonxi.py
  echo "Integration diagnostics, including upstream warnings: $integration_log"
fi
echo 'Local checks passed. Remote CI and official acceptance are separate.'
