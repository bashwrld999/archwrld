#!/bin/bash

set -euo pipefail

GITHUB_USER="bashwrld999"
BRANCH="main"
HASH=""
ARTIFACT="archwrld-${BRANCH}"

if [ -n "$HASH" ]; then
  curl -sL -o "${ARTIFACT}.zip" "https://github.com/${GITHUB_USER}/archwrld/archive/${HASH}.zip"
  bsdtar -x -f "${ARTIFACT}.zip"
else
  curl -sL -o "${ARTIFACT}.zip" "https://github.com/${GITHUB_USER}/archwrld/archive/refs/heads/${BRANCH}.zip"
  bsdtar -x -f "${ARTIFACT}.zip"
fi