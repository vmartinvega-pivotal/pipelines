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

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Checks if last commit is from maven-release-plugin, if so exits
checkLasCommit

# Add properties as environment variables
exportKeyValProperties

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"
touch $propsFile

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Sonarqube ---"
#mvn --batch-mode sonar:sonar -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Dsonar.branch=${SONAR_BRANCH}
echo "--- Sonarqube ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
