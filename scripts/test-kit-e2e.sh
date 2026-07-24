#!/usr/bin/env bash

set -euo pipefail

readonly APP_NAME=sbx-kits-contrib-tck
POLICY=${POLICY-deny-all}

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

if ! command -v sbx >/dev/null 2>&1; then
  echo "sbx not on PATH; install it from https://github.com/docker/sbx-releases" >&2
  exit 1
fi

probe_err=$(sbx --app-name "$APP_NAME" ls 2>&1 >/dev/null) || {
  cat >&2 <<EOF
The scoped sbx daemon is not usable:

$probe_err

Authenticate it with:
  sbx --app-name $APP_NAME login
EOF
  exit 1
}
unset probe_err

if [ -n "$POLICY" ]; then
  echo "Setting --app-name=$APP_NAME global policy to $POLICY"
  if ! sbx --app-name "$APP_NAME" policy init "$POLICY" >/dev/null 2>&1; then
    sbx --app-name "$APP_NAME" policy reset --force
    sbx --app-name "$APP_NAME" policy init "$POLICY"
  fi
fi

on_exit() {
  rc=$?
  if [ "$rc" -ne 0 ]; then
    cat >&2 <<EOF

E2E test failed. Inspect blocked requests with:
  sbx --app-name $APP_NAME ls
  sbx --app-name $APP_NAME policy log <sandbox-name>
EOF
  fi
  exit "$rc"
}
trap on_exit EXIT

cd "$REPO_ROOT"
KIT_UNDER_TEST="$kit_abs" go test \
  -tags=e2e \
  -v \
  -count=1 \
  -timeout 25m \
  -run '^TestE2EKit$' \
  "$@" \
  github.com/docker/sbx-kits-contrib/tck
