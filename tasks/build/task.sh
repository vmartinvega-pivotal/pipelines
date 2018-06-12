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
export TRUSTSTORE_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/settings/${TRUSTSTORE}"

echo "Generating settings.xml / gradle properties for Maven in local m2"
# shellcheck source=/dev/null
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/generate-settings.sh

echo "Storing private key in the container to access git"
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/store-github-private-key.sh


propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"
touch $propsFile

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Building ---"
#mvn -s ${MAVEN_SETTINGS} -X clean install -DskipTests=true -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} ${BUILD_OPTIONS}
mvn -X clean install -DskipTests=true ${BUILD_OPTIONS}
echo "--- Building ---"
echo ""

# Adding values to keyvalout
BUILD_DATE=`date`
echo "BUILD_DATE=${BUILD_DATE}" >> "${propsFile}"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
