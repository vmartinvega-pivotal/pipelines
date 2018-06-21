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

echo "-- Setting up scdf server ..."

# Login PCF
cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

# Get the urls for the PCF and stores them in environment variables
getPCFUrls ${PWS_ORG} ${PWS_SPACE}

# Deploys scdf server with a specific service name and service plan in the configured organization and space

if [[ ${DEPLOY_SCDF_SERVICE_INSTANCE} = "true" ]]
then
  echo "DEBUG: Deploying SCDF ..."

  # TODO: Can be the latest version in the git repository or configured!!
  export PASSED_TAG_VERSION_DEPLOYING="V1.0.2"

  # Deploys the scdf server
  cfSCDFDeploy ${SCDF_SERVICE_NAME} ${SCDF_SERVICE_PLAN} ${ENVIRONMENT_DEPLOYING} ${TAG_VERSION_DEPLOYING}

  # Modifies the environment configuration for the scdf server created to have the right nexus url, user and password
  scdfChangeEnvironment ${SCDF_ORG_FOR_SKIPPER_AND_DATAFLOW} ${PASSED_SCDF_SERVER_GUID} ${PWS_ORG} ${PWS_SPACE} ${NEXUS_USERNAME} ${NEXUS_PASSWORD} ${NEXUS_URL}
else
  echo "DEBUG: Using scdf configured: ${SCDF_SERVER_URL}"

  export PASSED_SCDF_SERVER_NAME="Configured-scdf-server"

  export PASSED_SCDF_SERVER_URL=${SCDF_SERVER_URL}
fi

echo "-- Setting up scdf server ..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
