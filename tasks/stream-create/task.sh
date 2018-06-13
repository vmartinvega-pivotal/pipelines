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

# Add properties from streamCreate.properties as environment variables
exportKeyValPropertiesForDeploying ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/streamCreate.properties

echo "-- Stream create ..."

#will replace the environment variables in your file with their corresponding value. The variable names must consist solely of alphanumeric #or underscore ASCII characters, not start with a digit and be nonempty; otherwise such a variable reference is ignored.
envsubst < ${ROOT_FOLDER}/${REPO_RESOURCE}/pcf-scdf-deploy-${TIM_ENVIRONMENT}/streamCreate.df >> ${TMPDIR}/streamCreate.df

java -jar ${ROOT_FOLDER}/${TOOLS_RESOURCE}/scdf/spring-cloud-dataflow-server-local-1.5.1.RELEASE.jar --dataflow.uri=${PASSED_SCDF_SERVER_URL}  --spring.shell.commandFile=${TMPDIR}/streamCreate.df

echo "-- Stream Create ..."

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
