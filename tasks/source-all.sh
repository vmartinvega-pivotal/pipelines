#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

echo "Generating settings.xml / gradle properties for Maven in local m2"
# shellcheck source=/dev/null
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/generate-settings.sh

echo "Storing private key in the container to access git"
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/store-github-private-key.sh

echo "Sourcing resource utils"
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/resource-utils.sh
