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

echo "--- Undeploy App ---"

# Login into PCF
cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

# TODO: Run all scripts to undeploy
#  01..
#  02..

# TODO: undeploy all apps from scdf

# TODO: delete all services created
pcfDeleteRabbitService ${PASSED_RABBIT_SERVICE_NAME} ${PASSED_RABBIT_SERVICE_KEY_NAME}

# TODO: delete SCDF service
cfSCDFDestroy ${PASSED_SCDF_SERVER_NAME}

echo "--- Undeploy App ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
