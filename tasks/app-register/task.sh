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

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

DF_FILE=""
PROPERTIES_FILE=""

if [[ $TASK_COMMAND = "appregister" ]]
then
  DF_FILE="appRegister.df"

  # TODO: This folder and environment variable will be create in another task, with all libs downloaded from NEXUS
  export ROOT_FOLDER_FOR_LIBS="${ROOT_FOLDER}/${REPO_RESOURCE}/libs"
fi

if [[ $TASK_COMMAND = "createstream" ]]
then
  DF_FILE="appRegister.df"
fi

# TODO: This folder and environment variable will be create in another task, with all libs downloaded from NEXUS
export ROOT_FOLDER_FOR_LIBS="${ROOT_FOLDER}/${REPO_RESOURCE}/libs"

echo "-- Executing shell script ..."

#will replace the environment variables in your file with their corresponding value. The variable names must consist solely of alphanumeric #or underscore ASCII characters, not start with a digit and be nonempty; otherwise such a variable reference is ignored.
envsubst < ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/appRegister.df >> ${TMPDIR}/appRegister.df

echo "PASSED_SCDF_SERVER_URL:${PASSED_SCDF_SERVER_URL}"

java -jar ${ROOT_FOLDER}/${TOOLS_RESOURCE}/scdf/spring-cloud-dataflow-shell-1.5.1.RELEASE.jar --dataflow.uri="${PASSED_SCDF_SERVER_URL}"  --spring.shell.commandFile="${TMPDIR}/appRegister.df"

echo "-- Executing shell script ..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
