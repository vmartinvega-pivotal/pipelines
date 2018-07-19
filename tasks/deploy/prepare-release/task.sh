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

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Prepare Release ---"

# Creates the files to be uploaded
#TODO: create the app-descriptor.df apps-version.env and compiled files and put them in the right place
# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

prepareScriptsToDeploy

# Move the app-descriptor.df for the logical microservice
mv ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df "${ROOT_FOLDER}/${REPO_RESOURCE}"/app-descriptor.df

mv ${TMPDIR}/${REPO_RESOURCE}/apps-version.env "${ROOT_FOLDER}/${REPO_RESOURCE}"/apps-version.env

echo "app import --uri file:${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df" >> ${TMPDIR}/app-register.df


git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

mvn --batch-mode release:clean release:prepare -DdryRun=true -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments=" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

cp pom.xml.next pom.xml.backup

mvn release:clean -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

git add pom.xml
  
git commit -m "[ci skip] Adding pom.xml resolved"

echo "--- Prepare Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${FILES}/"

echo "Done!!"
