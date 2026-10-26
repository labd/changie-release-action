#!/usr/bin/env bash
# Decides whether the current commit is a release that still needs to be
# published, and creates the tag when it does not exist yet.
#
# A commit is a release when the latest changie version:
#   - has no tag yet (the release PR was just merged), or
#   - is tagged on this exact commit but has no published GitHub release yet
#     (a previous attempt failed, so re-running the workflow retries it).
#
# Required env: GH_TOKEN, GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_OUTPUT, VERSION
set -euo pipefail

# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

released=false

if [ -z "${VERSION}" ]; then
  echo "No changie version found, nothing to release"
elif [ ! -f "${CHANGES_DIR}/${VERSION}.${VERSION_EXT}" ]; then
  echo "No notes for ${VERSION} in ${CHANGES_DIR}, nothing to release"
else
  # On a 404 gh prints the error body to stdout, so rely on the exit code
  if ! tag_sha=$(gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/${VERSION}" --jq '.object.sha' 2>/dev/null); then
    tag_sha=""
  fi

  if [ -z "${tag_sha}" ]; then
    echo "Tag ${VERSION} does not exist, creating it on ${GITHUB_SHA}"
    gh api "repos/${GITHUB_REPOSITORY}/git/refs" \
      -f ref="refs/tags/${VERSION}" \
      -f sha="${GITHUB_SHA}" > /dev/null
    released=true
  elif [ "${tag_sha}" = "${GITHUB_SHA}" ]; then
    if gh api "repos/${GITHUB_REPOSITORY}/releases/tags/${VERSION}" > /dev/null 2>&1; then
      echo "Release ${VERSION} is already published"
    else
      echo "Tag ${VERSION} exists on this commit but is not published yet, retrying"
      released=true
    fi
  else
    echo "Version ${VERSION} is already tagged on another commit"
  fi
fi

# Make the tag available to later steps in this job (e.g. goreleaser)
if [ "${released}" = "true" ]; then
  git tag --force "${VERSION}" "${GITHUB_SHA}"
fi

echo "released=${released}" >> "$GITHUB_OUTPUT"
