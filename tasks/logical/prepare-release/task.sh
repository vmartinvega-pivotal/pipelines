#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export CONFIG_RESOURCE=config
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

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

mvn --batch-mode release:clean release:prepare -DdryRun=true -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments=" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

cp pom.xml.next pom.xml.backup

mvn release:clean -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Creates the files to be uploaded
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}
cp -r ${ROOT_FOLDER}/${CONFIG_RESOURCE} ${TMPDIR}
cd ${TMPDIR}/${REPO_RESOURCE}

prepareScriptsToDeploy

echo "after prepared..."
ls ${TMPDIR}/${REPO_RESOURCE}"/

# Move all compiled files to the repo
mv ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df "${ROOT_FOLDER}/${REPO_RESOURCE}"/app-descriptor.df
mv ${TMPDIR}/${REPO_RESOURCE}/apps-version.env "${ROOT_FOLDER}/${REPO_RESOURCE}"/apps-version.env

if [ -d ${ROOT_FOLDER}/${REPO_RESOURCE}/compiled ]; then
    rm -Rf compiled
fi 
cp -r ${TMPDIR}/${REPO_RESOURCE}/compiled "${ROOT_FOLDER}/${REPO_RESOURCE}"/

echo "debug"
ls ${ROOT_FOLDER}/${REPO_RESOURCE}"/

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

git add pom.xml
git add app-descriptor.df
git add apps-version.env
git add compiled/*

git commit -m "[ci skip] Adding pom.xml for the current version, and all compiled files"

echo "--- Prepare Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${FILES}/"

echo "Done!!"
