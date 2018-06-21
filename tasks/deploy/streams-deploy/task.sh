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

ROOT_FOLDER_SCDF_SCRIPTS="${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy"

# Creates the app-register file
echo "app import --uri file:${ROOT_FOLDER_SCDF_SCRIPTS}/app-descriptor.df" >> ${TMPDIR}/app-register.df

# Register all microservices
scdf_shell ${PASSED_SCDF_SERVER_URL} "${TMPDIR}/app-register.df"

cd "${ROOT_FOLDER_SCDF_SCRIPTS}/scripts-deploy" || exit

# Run all scripts in order
for file in `ls *.sh | sort -V`; do 

  echo "Sourcing file: ${file}"

  source ${file}

done

# Creating the streams
echo "DEBUG: Creating the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/create.df"


# Deploying the streams
echo "DEBUG: Deploying the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/deploy.df"

echo "-- Deploying streams ..."

# Adding values to keyvalout
passKeyValProperties

echo "Done!!"
