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
export MAVEN_SETTINGS_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/settings/${MAVEN_SETTINGS}"

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"

echo "--- Task Params ---"
echo "MAVEN_SETTINGS: [${MAVEN_SETTINGS}]"
echo "MAVEN_SETTINGS_FILE: [${MAVEN_SETTINGS_FILE}]"
echo "BUILD_OPTIONS: [${BUILD_OPTIONS}]"
echo "TRUSTSTORE: [${TRUSTSTORE}]"
echo "TRUSTSTORE_FILE: [${TRUSTSTORE_FILE}]"
echo "--- Task Params ---"
echo ""

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
