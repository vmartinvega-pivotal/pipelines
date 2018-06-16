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

echo "--- Deploy SpringBoot app ---"

# Login into PCF
cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

# Gets APPs URL
getAppsUrl ${PWS_ORG} ${PWS_SPACE}

# Check if found the url
if [ -z "${PASSED_APPS_URL}" ]; then
    echo "Not found Apps Url, exiting..."
    exit 1
fi

# Find the jar to be deployed
ARTIFACT_ID="unzip-sink"
ARTIFACT_VERSION="1.0.0-SNAPSHOT"
JAR_FILE=$(find ../ -name "${ARTIFACT_ID}-${ARTIFACT_VERSION}.jar")

# Creates a random name to deploy the app
RANDOM_HOST=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
APP_NAME="${ARTIFACT_ID}-${RANDOM_HOST}"

# Push the app to PCF
cf push ${APP_NAME} -p ${JAR_FILE}

APP_STATE=$(cf curl ${PASSED_APPS_URL} | jq '.resources[].entity | select(.name == "'${APP_NAME}'" ) | .state' | sed -e 's/^"//' -e 's/"$//')

# Checks the state of the application
if [[ ${APP_STATE} = "STARTED" ]]
then
  echo "DEBUG: Started app with name ${APP_NAME} in the organization ${PWS_ORG} and space ${PWS_SPACE}"
  export PASSED_APPLICATION_NAME=${APP_NAME}
else
  echo "ERROR: The application ${APP_NAME} has a state of ${APP_STATE} that is not started, existing..."
  cf delete ${APP_NAME} -r -f
  exit 1
fi

echo "--- Deploy SpringBoot app ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
