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
ROOT_FOLDER_SCDF_SCRIPTS="${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${ENVIRONMENT_DEPLOYING}"

function setFileName(){
  DF_FILE=$1

  if [ ! -f "${ROOT_FOLDER_SCDF_SCRIPTS}/$2" ]; then
    touch ${ROOT_FOLDER_SCDF_SCRIPTS}/$2
  fi

  PROPERTIES_FILE=$2
}

echo "-- Executing ${STAGE} ..."

if [[ $STAGE = "appregister" ]]
then 
  setFileName "appRegister.df" "appRegister.properties"
fi

if [[ $STAGE = "createstream" ]]
then 
  setFileName "createStream.df" "createStream.properties"
fi

if [[ $STAGE = "deploystream" ]]
then 
  setFileName "deployStream.df" "deployStream.properties"
fi

exportKeyValPropertiesForDeploying ${ROOT_FOLDER_SCDF_SCRIPTS}/${PROPERTIES_FILE}

envsubst < ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${ENVIRONMENT_DEPLOYING}/${DF_FILE} >> ${TMPDIR}/${DF_FILE}

java -jar ${ROOT_FOLDER}/${TOOLS_RESOURCE}/scdf/spring-cloud-dataflow-shell-1.5.1.RELEASE.jar --dataflow.uri=${PASSED_SCDF_SERVER_URL}  --spring.shell.commandFile=${TMPDIR}/${DF_FILE}

echo "-- Executing ${STAGE} ..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
