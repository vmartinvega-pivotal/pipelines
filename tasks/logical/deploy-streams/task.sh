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
export CONFIG_RESOURCE=config
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

echo "--- Deploy Streams ---"

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

if [[ ! -v PASSED_TAG_RELEASED_CREATED ]]; then
  echo "DEBUG: PASSED_TAG_RELEASED_CREATED is not set, skipping"
elif [[ -z "$PASSED_TAG_RELEASED_CREATED" ]]; then
  echo "PASSED_TAG_RELEASED_CREATED is set to the empty string, skipping"
else
  echo "PASSED_TAG_RELEASED_CREATED has the value: $PASSED_TAG_RELEASED_CREATED"
  echo "DEBUG: checking out the verson "${PASSED_TAG_RELEASED_CREATED}
  git checkout tags/${PASSED_TAG_RELEASED_CREATED}
fi

echo "Deploying to ${ENVIRONMENT_TO_DEPLOY}"

chmod +x ${ROOT_FOLDER}/${CONFIG_RESOURCE}/NFS-bind.sh

#./microservice.sh ../${CONFIG_RESOURCE}/${ENVIRONMENT_TO_DEPLOY}.env microservice.env redeploy  
#./microservice.sh ../${CONFIG_RESOURCE}/${ENVIRONMENT_TO_DEPLOY}.env microservice.env deploy

echo "--- Deploy Streams ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
