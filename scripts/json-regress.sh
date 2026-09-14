#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
binary="$(bash "$project_dir/scripts/build-cli.sh")"
# Preserve caller cwd so relative input/output paths refer to the user's files.
exec "$binary" "$@"
