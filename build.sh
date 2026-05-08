#!/bin/bash
SCRIPT_DIR="$( dirname -- "$( readlink -f -- "$0" )" )"

LATEST_RELEASE_URL=https://api.github.com/repos/infisical/cli/releases/latest
IMAGE_REPO=ghcr.io/qeon/infisical-cli

# we assume docker has been ready to do stuffs.
REQUIRED_BINS=( curl jq )
for REQUIRED_BIN in "${REQUIRED_BINS[@]}"; do
    which "${REQUIRED_BIN}" >/dev/null 2>&1
    [ "$?" -ne "0" ] && { >&2 echo "error: ${REQUIRED_BIN} not found in PATH"; exit 1; }
done

# check latest release
LATEST_RELEASE_JSON="$(curl "${LATEST_RELEASE_URL}" 2>/dev/null)"
[ "$?" -ne "0" ] && { >&2 echo "error: failed fetching latest release data."; exit 1; }

LATEST_RELEASE="$(echo "${LATEST_RELEASE_JSON}" | jq -r .tag_name)"

# check if it's already exist.
docker manifest inspect ${IMAGE_REPO}:${LATEST_RELEASE} >/dev/null 2>&1
if [ "$?" -ne "0" ]; then
    # not exist, create.
    # cat latest_release.json  | jq -r '.assets[] | select (.name | test("^cli.*_linux_amd64"))'
    LATEST_RELEASE_URL="$(echo $LATEST_RELEASE_JSON | jq -r '.assets[] | select (.name | test ("^cli.*_linux_amd64")) | .browser_download_url')"
    docker build \
        -f "${SCRIPT_DIR}/Dockerfile" \
        --build-arg "DOWNLOAD_URL=${LATEST_RELEASE_URL}" \
        -t "${IMAGE_REPO}:latest" \
        -t "${IMAGE_REPO}:${LATEST_RELEASE}" \
        --label "org.opencontainers.image.version=${LATEST_RELEASE}" \
        .
fi
exit 0
