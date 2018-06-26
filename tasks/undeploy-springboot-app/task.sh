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

echo "--- Undeploy SpringBoot app ---"

# Login into PCF
cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

# Gets APPs URL
getAppsUrl ${PWS_ORG} ${PWS_SPACE}

# Push the app to PCF
cf delete app ${PASSED_SPRING_BOOT_APP_NAME} -f -r

echo "--- Undeploy SpringBoot app ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
