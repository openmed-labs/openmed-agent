#!/usr/bin/env bash
# Older OpenMed Agent builds print this address. The installer is served from
# install.openmed.life; this script downloads it and runs it.
set -euo pipefail
tmp="$(mktemp "${TMPDIR:-/tmp}/openmed-install.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
curl -fsSL https://install.openmed.life/install.sh -o "$tmp"
bash "$tmp" "$@"
