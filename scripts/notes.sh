#!/usr/bin/env bash
# Usage: notes.sh <version> <output-file>
#
# Writes the changie notes of <version> to <output-file>, without the version
# header line, so it can be used as GitHub release notes or PR body.
set -euo pipefail

version="$1"
output="$2"

# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

source_file="${CHANGES_DIR}/${version}.${VERSION_EXT}"
if [ ! -f "$source_file" ]; then
  echo "::error::Changie notes ${source_file} not found"
  exit 1
fi

# Drop the first line when it is the version header, and leading blank lines
awk -v version="$version" '
  NR == 1 && index($0, version) { next }
  !started && /^[[:space:]]*$/ { next }
  { started = 1; print }
' "$source_file" > "$output"
