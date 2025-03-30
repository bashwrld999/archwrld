#!/bin/bash

set -euo pipefail

GITHUB_USER="bashwrld999"
BRANCH="main"
ARTIFACT="archwrld-${BRANCH}"

curl -sL -o "${ARTIFACT}.zip" "https://github.com/${GITHUB_USER}/archwrld/archive/refs/heads/${BRANCH}.zip"
bsdtar -x -f "${ARTIFACT}.zip"

chmod +x ./${ARTIFACT}/*.sh

./${ARTIFACT}/archwrld.sh
