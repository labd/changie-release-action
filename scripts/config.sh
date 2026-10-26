#!/usr/bin/env bash
# Reads the directories and extension from .changie.yaml and exposes them as
# CHANGES_DIR, UNRELEASED_DIR and VERSION_EXT. Meant to be sourced.

changie_config() {
  local key="$1" default="$2" file value
  for file in .changie.yaml .changie.yml; do
    [ -f "$file" ] || continue
    value=$(sed -n "s/^${key}:[[:space:]]*//p" "$file" | head -n1 | tr -d "\"'\r")
    break
  done
  echo "${value:-$default}"
}

CHANGES_DIR=$(changie_config changesDir .changes)
UNRELEASED_DIR=$(changie_config unreleasedDir unreleased)
VERSION_EXT=$(changie_config versionExt md)
export CHANGES_DIR UNRELEASED_DIR VERSION_EXT
