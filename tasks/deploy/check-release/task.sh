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

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

echo "--- Check Logical Release ---"

chmod 777 ${TRUST_STORE_FILE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Generate the app-descriptor for the microservice from the template
if [ -f app-descriptor.df ]; then
  rm app-descriptor.df
fi

if [ -f app-version-collaudo-evolutivo.sh ]; then
  rm app-version-collaudo-evolutivo.sh
fi

if [ -f app-version-prod.sh ]; then
  rm app-version-prod.sh
fi

python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df app-version-collaudo-evolutivo-template.sh app-version-collaudo-evolutivo.sh app-version-prod-template.sh app-version-prod.sh maven-binaries-file

TAG_VERSION_APP_DESCRIPTOR=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-descriptor.df)
if [[ $TAG_VERSION_APP_DESCRIPTOR = "true" ]]
then
  echo "Some physical microservices where not resolved in app-descriptor.df !! Existing ..."
  exit 1
fi

TAG_VERSION_COLLAUDO=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-version-collaudo-evolutivo.sh)
if [[ $TAG_VERSION_COLLAUDO = "true" ]]
then
  echo "Some physical microservices where not resolved in app-version-collaudo-evolutivo.sh !! Existing ..."
  exit 1
fi

TAG_VERSION_PROD=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-version-prod.sh)
if [[ $TAG_VERSION_PROD = "true" ]]
then
  echo "Some physical microservices where not resolved in app-version-prod.sh !! Existing ..."
  exit 1
fi

echo "DEBUG: app-descriptor created..."
cat app-descriptor.df

echo "DEBUG: app-version-collaudo-evolutivo.sh created..."
cat app-version-collaudo-evolutivo.sh

echo "DEBUG: app-version-prod.sh created..."
cat app-version-prod.sh

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

rm -Rf ${TMPDIR}/${REPO_RESOURCE}

echo "--- Check Logical Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
