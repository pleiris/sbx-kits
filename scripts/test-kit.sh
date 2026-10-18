#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
  kit_arg=$1
  shift
else
  kit_arg=$PWD
fi

if [ -d "$kit_arg" ]; then
  kit_abs=$(cd "$kit_arg" && pwd)
elif [ -d "$REPO_ROOT/$kit_arg" ]; then
  kit_abs=$(cd "$REPO_ROOT/$kit_arg" && pwd)
else
  echo "kit directory not found: $kit_arg" >&2
  exit 1
fi

if [ ! -f "$kit_abs/spec.yaml" ] && [ ! -f "$kit_abs/spec.yml" ]; then
  echo "no spec.yaml or spec.yml in $kit_abs" >&2
  exit 1
fi

test_args=()
if [ -f "$kit_abs/testdata/tck-skip-install" ]; then
  echo "Skipping TCK install execution; this kit requires sandbox-managed credentials"
  test_args+=(-short)
fi

cd "$REPO_ROOT"
KIT="$kit_abs" exec go test \
  -v \
  -count=1 \
  -timeout 10m \
  -run '^TestKits$' \
  "${test_args[@]}" \
  "$@" \
  .
