#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repoput
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Pvcs Upload ---"

# If a new release was created
if [[ ${PASSED_NEW_LOGICAL_RELEASE} = "true" ]]
then
  # Get all binaries from file to be uploaded to PVCS
  echo "checkout pvcs url: ${PVCS_URL}"
  PVCS_PATH=${TMPDIR}/pvcs/vicente_test
  mkdir -p ${PVCS_PATH} 
  cd ${PVCS_PATH}
  svn checkout --config-option servers:global:store-plaintext-passwords=no --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD} ${PVCS_URL}
  
  FOLDER_TO_WORK=${PVCS_PATH}/${PVCS_CHECKOUTDIR}/vicente
  if [ -f ${FOLDER_TO_WORK} ]; then
    rm -Rf ${FOLDER_TO_WORK}
  fi
  mkdir ${FOLDER_TO_WORK}
  cd ${FOLDER_TO_WORK}
  
  
  if [ -f ${FOLDER_TO_WORK}/logical ]; then
    rm -Rf ${FOLDER_TO_WORK}/logical
  fi
  mkdir ${FOLDER_TO_WORK}/logical

  cp -R ${ROOT_FOLDER}/${REPO_RESOURCE} ${FOLDER_TO_WORK}/logical

  #mkdir ${PVCS_PATH}/binaries

  #while IFS= read -r artifact
  #do
   #mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:get -Dartifact=${artifact} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -Ddest=${PVCS_PATH}/binaries -  Dtransitive=false
  #done < "${TMPDIR}/${REPO_RESOURCE}/maven-binaries-file"

  #svn commit -m "Logical microservice version ${PASSED_TAG_RELEASED_CREATED}"
fi

echo "--- Pvcs Upload ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
