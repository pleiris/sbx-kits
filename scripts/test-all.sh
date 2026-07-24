#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

mapfile -t kits < <(
  for spec in "$REPO_ROOT"/*/spec.yaml "$REPO_ROOT"/*/spec.yml; do
    [ -f "$spec" ] && dirname "$spec"
  done | sort -u
)

if [ "${#kits[@]}" -eq 0 ]; then
  echo "no kits found" >&2
  exit 1
fi

for kit in "${kits[@]}"; do
  "$SCRIPT_DIR/test-kit.sh" "$kit" "$@"
done
