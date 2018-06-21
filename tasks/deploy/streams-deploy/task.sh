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

echo "-- Deploying streams ..."

ROOT_FOLDER_SCDF_SCRIPTS="${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${ENVIRONMENT_DEPLOYING}"

# Creates the app-register file
echo "app import --uri file:${ROOT_FOLDER_SCDF_SCRIPTS}/app-descriptor.df" >> ${TMPDIR}/app-register.df

# Register all microservices
scdf_shell ${PASSED_SCDF_SERVER_URL} "${TMPDIR}/app-register.df"

echo "-- Deploying streams ..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
