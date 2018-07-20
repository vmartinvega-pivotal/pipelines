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

echo "--- Pvcs Upload ---"

echo "DEBUG: checking out the verson "${PASSED_TAG_RELEASED_CREATED}
git checkout tags/${PASSED_TAG_RELEASED_CREATED}

# Get all binaries from file to be uploaded to PVCS
echo "checkout pvcs url: ${PVCS_URL}"
PVCS_PATH=${TMPDIR}/pvcs/vicente_test
mkdir -p ${PVCS_PATH} 
cd ${PVCS_PATH}

svn checkout --config-option servers:global:store-plaintext-passwords=no --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD} ${PVCS_URL}

FOLDER_TO_WORK_IN_PVCS=${PVCS_PATH}/${PVCS_CHECKOUTDIR}/vicente
if [ -d ${FOLDER_TO_WORK_IN_PVCS} ]; then
  rm -Rf ${FOLDER_TO_WORK_IN_PVCS}
fi
mkdir ${FOLDER_TO_WORK_IN_PVCS}
cd ${FOLDER_TO_WORK_IN_PVCS}

#TODO: COPIAR LO QUE CORRESPONDA, FUENTES  

cp "${ROOT_FOLDER}/${REPO_RESOURCE}"/pom.xml ${FOLDER_TO_WORK_IN_PVCS} 

svn add --force ${FOLDER_TO_WORK_IN_PVCS}

#mkdir ${PVCS_PATH}/binaries

#while IFS= read -r artifact
#do
#mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:get -Dartifact=${artifact} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -Ddest=${PVCS_PATH}/binaries -  Dtransitive=false
#done < "${TMPDIR}/${REPO_RESOURCE}/maven-binaries-file"

svn commit -m "Logical microservice version ${PASSED_TAG_RELEASED_CREATED}" --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD}

echo "--- Pvcs Upload ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
