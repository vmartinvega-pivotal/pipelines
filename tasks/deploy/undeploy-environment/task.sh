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

echo "-- Undeploy Environment for version ${PASSED_TAG_VERSION_DEPLOYING} and environment to deploy ${ENVIRONMENT_DEPLOYING}..."

# Destroy all streams created
ROOT_FOLDER_SCDF_SCRIPTS="${ROOT_FOLDER}/${REPO_RESOURCE}/ci/pcf-scdf-streams-${ENVIRONMENT_DEPLOYING}"

cd "${ROOT_FOLDER_SCDF_SCRIPTS}" || exit

# Run all scripts in order
for file in `ls *.sh | sort -V`; do 

  echo "Sourcing file: ${file}"

  source ${file}

done

# Undeploying the streams
echo "DEBUG: Undeploying the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/undeploy.df"

# Destroying the streams
echo "DEBUG: Destroying the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/destroy.df"

# If it is neccesary to access PCF does the login and gets all pcf urls 
if [[ ${DEPLOY_SCDF_SERVICE_INSTANCE} = "true" ]] || [[ ${DEPLOY_RABBITMQ_SERVICE_INSTANCE} = "true" ]]
then
  # Login PCF
  cfLogin ${PWS_API} ${PWS_USER} ${PWS_PWD} ${PWS_ORG} ${PWS_SPACE}

  # Get the urls for the PCF and stores them in environment variables
  getPCFUrls ${PWS_ORG} ${PWS_SPACE}
fi

# Checks if is needed to rabbitmq instance
if [[ ${DEPLOY_RABBITMQ_SERVICE_INSTANCE} = "true" ]]
then
  echo "DEBUG: Removing RabbitMQ ..."

  # Removes the rabbitmq created previously  
  pcfDeleteRabbitService ${PASSED_RABBIT_SERVICE_NAME} ${PASSED_RABBIT_SERVICE_KEY_NAME}
fi

# Checks if is needed to deploy scdf server
if [[ ${DEPLOY_SCDF_SERVICE_INSTANCE} = "true" ]]
then
  echo "DEBUG: Removing SCDF ..."

  # Destroys the scdf server created previously
  cfSCDFDestroy ${PASSED_SCDF_SERVER_NAME}
fi

echo "-- Undeploy Environment for version ${PASSED_TAG_VERSION_DEPLOYING} and environment to deploy ${ENVIRONMENT_DEPLOYING}..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
