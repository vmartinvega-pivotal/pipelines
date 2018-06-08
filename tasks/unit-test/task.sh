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

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"

echo "--- Task Params ---"
echo ""
echo "MAVEN_SETTINGS: [${MAVEN_SETTINGS}]"
echo "BUILD_OPTIONS: [${BUILD_OPTIONS}]"
echo ""
echo "--- Task Params ---"

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Testing ---"
echo ""
mvn -s ${MAVEN_SETTINGS} test -Dmaven.test.failure.ignore=true ${BUILD_OPTIONS}
echo ""
echo "--- Testing ---"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
