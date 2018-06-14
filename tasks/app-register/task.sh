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

DF_FILE=""
PROPERTIES_FILE=""

function setFileName(){
  DF_FILE=$1

  if [ ! -f ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/$2 ]; then
    touch ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/$2
  fi

  PROPERTIES_FILE=$2
}

if [[ $TASK_COMMAND = "appregister" ]]
then
  echo "-- Executing appregister ..."
  setFileName "appRegister.df" "appRegister.properties"

  # TODO: This folder and environment variable will be create in another task, with all libs downloaded from NEXUS
  export ROOT_FOLDER_FOR_LIBS="${ROOT_FOLDER}/${REPO_RESOURCE}/libs"
fi

if [[ $TASK_COMMAND = "createstream" ]]
then
  echo "-- Executing createstream ..."
  setFileName "createStream.df" "createStream.properties"
fi

if [[ $TASK_COMMAND = "deploystream" ]]
then
  echo "-- Executing deploystream ..."
  setFileName "deployStream.df" "deployStream.properties"
fi

exportKeyValPropertiesForDeploying ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/${PROPERTIES_FILE}

# Will replace the environment variables in your file with their corresponding value. 
# The variable names must consist solely of alphanumeric or underscore ASCII characters, 
#not start with a digit and be nonempty; otherwise such a variable reference is ignored.
envsubst < ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/${DF_FILE} >> ${TMPDIR}/${DF_FILE}

java -jar ${ROOT_FOLDER}/${TOOLS_RESOURCE}/scdf/spring-cloud-dataflow-shell-1.5.1.RELEASE.jar --dataflow.uri=${PASSED_SCDF_SERVER_URL}  --spring.shell.commandFile=${TMPDIR}/appRegister.df

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
