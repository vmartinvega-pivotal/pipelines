#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repoput
export FILES_FROM_PREPARE_RELEASE=out-preprare-release
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export FILES=out-release-step1
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Create Release ---"

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

git checkout -f ${CURRENT_BRANCH}

mvn --batch-mode release:clean release:prepare -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}  -DscmCommentPrefix="[ci skip]" 

mv ${ROOT_FOLDER}/${FILES_FROM_PREPARE_RELEASE}/pom.xml.backup pom.xml

git add pom.xml

git commit -m "[ci skip] Restoring pom.xml to create the release"

echo "--- Create Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${FILES}/"

echo "Done!!"