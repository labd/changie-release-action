#!/usr/bin/env bash
# Decides whether the latest changie version still needs to be released: it
# has changie notes but no tag on GitHub yet.
#
# The tag is only created locally here. It is created on GitHub when the
# release is published (by create-release or the goreleaser action), so a
# failed release leaves no tag behind and the next push to the branch retries.
#
# Required env: GH_TOKEN, GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_OUTPUT, VERSION
set -euo pipefail

# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

released=false

# Prints "true" or "false", and fails on anything other than a 404 so an API
# error never triggers a release
tag_exists() {
  local output
  if output=$(gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/$1" 2>&1); then
    echo true
  elif echo "${output}" | grep -q 'HTTP 404'; then
    echo false
  else
    echo "::error::Could not check tag $1: ${output}" >&2
    return 1
  fi
}

if [ -z "${VERSION}" ]; then
  echo "No changie version found, nothing to release"
elif [ ! -f "${CHANGES_DIR}/${VERSION}.${VERSION_EXT}" ]; then
  echo "No notes for ${VERSION} in ${CHANGES_DIR}, nothing to release"
else
  # A separate assignment, so set -e stops the script when the check fails
  exists=$(tag_exists "${VERSION}")
  if [ "${exists}" = "true" ]; then
    echo "Version ${VERSION} is already tagged"
  else
    echo "Version ${VERSION} is not tagged yet, releasing ${GITHUB_SHA}"
    git tag --force "${VERSION}" "${GITHUB_SHA}"
    released=true
  fi
fi

echo "released=${released}" >> "$GITHUB_OUTPUT"
