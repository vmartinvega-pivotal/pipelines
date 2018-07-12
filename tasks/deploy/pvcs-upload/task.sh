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

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

# If a new release was created
if [[ ${PASSED_NEW_LOGICAL_RELEASE} = "true" ]]
then
  git fetch

  # Gets the release created previously
  git checkout -f "${PASSED_TAG_RELEASED_CREATED}"

  # Get all binaries from file to be uploaded to PVCS
  echo "checkout pvcs url: ${PVCS_URL}"
  PVCS_PATH=${TMPDIR}/pvcs/vicente_test
  mkdir -p ${PVCS_PATH} 
  cd ${PVCS_PATH}
  #svn checkout --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD} ${PVCS_URL}
  #cd ${PVCS_CHECKOUTDIR}

  mkdir ${PVCS_PATH}/binaries

  #while IFS= read -r artifact
  #do
   #mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:get -Dartifact=${artifact} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -Ddest=${PVCS_PATH}/binaries -  Dtransitive=false
  #done < "${TMPDIR}/${REPO_RESOURCE}/maven-binaries-file"
fi

echo "--- Pvcs Upload ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
