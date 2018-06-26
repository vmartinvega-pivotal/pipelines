#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

# TODO: Can be the latest version in the git repository or configured!!
export PASSED_TAG_VERSION_DEPLOYING="V1.0.2"

echo "-- Running SaopUI tests for version ${PASSED_TAG_VERSION_DEPLOYING} and environment ${ENVIRONMENT_DEPLOYING}..."

echo "-- Setting up Environment for version ${PASSED_TAG_VERSION_DEPLOYING} and environment ${ENVIRONMENT_DEPLOYING}..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"