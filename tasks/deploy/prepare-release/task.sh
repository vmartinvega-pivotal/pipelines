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

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Prepare Release ---"

chmod 777 ${TRUST_STORE_FILE}

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

# For insecure connections
# echo insecure >> ~/.curlrc

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Generate the app-descriptor for the microservice from the template
python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df app-versions.properties


echo "DEBUG: Adding the new app-descriptor.df "

cp ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}
  
echo "DEBUG: Addig the new app-versions.properties"

  
cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

git add --all
  
git commit -a -m "[ci skip] Adding all compiled file for the version"



rm -Rf cd ${TMPDIR}/${REPO_RESOURCE}

echo "--- Prepare Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
