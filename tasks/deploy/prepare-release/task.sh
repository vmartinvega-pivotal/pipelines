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
export FILES=out-preprare-release

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

echo "--- Prepare Release ---"

# Creates the files to be uploaded
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

prepareScriptsToDeploy

# Move all compiled files to the repo
mv ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df "${ROOT_FOLDER}/${REPO_RESOURCE}"/app-descriptor.df
mv ${TMPDIR}/${REPO_RESOURCE}/apps-version.env "${ROOT_FOLDER}/${REPO_RESOURCE}"/apps-version.env

if [ -f compiled ]; then
    rm -Rf compiled
fi 
mv ${TMPDIR}/${REPO_RESOURCE}/compiled "${ROOT_FOLDER}/${REPO_RESOURCE}"/

# Remove the temp repo
rm -Rf cd ${TMPDIR}/${REPO_RESOURCE}

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

mvn --batch-mode release:clean release:prepare -DdryRun=true -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments=" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

cp pom.xml.next pom.xml.backup

RELEASED_VERSION=$(getPomVersion pom.xml.backup)
export PASSED_TAG_RELEASED_CREATED="v"${RELEASED_VERSION}

mvn release:clean -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# I dont want to push this file
mv pom.xml.backup ..

git add --all

mv ../pom.xml.backup .

git commit -m "[ci skip] Adding pom.xml for the current version, and all compiled files"

echo "--- Prepare Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${FILES}/"

echo "Done!!"
