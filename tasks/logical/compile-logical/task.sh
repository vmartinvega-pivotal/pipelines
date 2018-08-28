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
export CONFIG_RESOURCE=config
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

TAG_VERSION_APP_DESCRIPTOR=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-descriptor.df)
if [[ $TAG_VERSION_APP_DESCRIPTOR = "true" ]]
then
  echo "Some physical microservices where not resolved in app-descriptor.df !! Existing ..."
  exit 1
fi

# Checks if there is some SNAPSHOT version in the apps-version.env file in that case if we are in the
# compilatino for release this proccess should fail
echo RESULT=$(cat ${ROOT_FOLDER}/${REPO_RESOURCE}/apps-version.env | grep SNAPSHOT | wc -l)
if [[ $RESULT = "0" ]]
then
  echo "DEBUG: Success!! There are not SNAPSHOT releases in the apps-version.env file"
else
  echo "DEBUG: Failed!! There are SNAPSHOT releases in the apps-version.env!!!" 
  exit 1
fi

echo "--- Compile Logical ---"

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

prepareScriptsToDeploy
retval=$?
if [ $retval -ne 0 ]; then
  echo "Something was wrong with the compilation!! Existing..."
  exit 1
fi

echo "--- Compile Logical ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
