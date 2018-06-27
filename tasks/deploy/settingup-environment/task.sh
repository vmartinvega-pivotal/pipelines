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

echo "-- Setting up Environment for version ${PASSED_TAG_VERSION_DEPLOYING} and environment to deploy ${ENVIRONMENT_DEPLOYING}..."

# If it is neccesary to access PCF does the login and gets all pcf urls 
if [[ ${DEPLOY_SCDF_SERVICE_INSTANCE} = "true" ]] || [[ ${DEPLOY_RABBITMQ_SERVICE_INSTANCE} = "true" ]]
then
  # Login PCF
  cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

  # Get the urls for the PCF and stores them in environment variables
  getPCFUrls ${PWS_ORG} ${PWS_SPACE}
fi

# Checks if is needed to deploy scdf server
if [[ ${DEPLOY_SCDF_SERVICE_INSTANCE} = "true" ]]
then
  echo "DEBUG: Deploying SCDF ..."

  # Deploys scdf server with a specific service name and service plan in the configured organization and space
  cfSCDFDeploy ${SCDF_SERVICE_NAME} ${SCDF_SERVICE_PLAN} ${ENVIRONMENT_DEPLOYING} ${PASSED_TAG_VERSION_DEPLOYING}

  # Modifies the environment configuration for the scdf server created to have the right nexus url, user and password
  scdfChangeEnvironment ${SCDF_ORG_FOR_SKIPPER_AND_DATAFLOW} ${PASSED_SCDF_SERVER_GUID} ${PWS_ORG} ${PWS_SPACE} ${NEXUS_USERNAME} ${NEXUS_PASSWORD} ${NEXUS_URL}
else
  echo "DEBUG: Using scdf configured: ${SCDF_SERVER_URL}"

  export PASSED_SCDF_SERVER_NAME="Configured-scdf-server"

  export PASSED_SCDF_SERVER_URL=${SCDF_SERVER_URL}
fi

# Checks if is needed to rabbitmq instance
if [[ ${DEPLOY_RABBITMQ_SERVICE_INSTANCE} = "true" ]]
then
  echo "DEBUG: Deploying RabbitMQ ..."
  
  # Deploying rabbitmq instance
  pcfSetupRabbitService ${RABBITMQ_SERVICE_NAME} ${RABBITMQ_SERVICE_PLAN} ${ENVIRONMENT_DEPLOYING} ${TAG_VERSION_DEPLOYING}

  # TODO: Create the exchange, queue and routing key
fi

echo "-- Setting up Environment for version ${PASSED_TAG_VERSION_DEPLOYING} and environment to deploy ${ENVIRONMENT_DEPLOYING}..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
