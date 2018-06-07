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

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "Packaging JAR"
./mvnw clean package -DskipTests

jar_count=`find ./target -type f -name *.jar | wc -l`

if [ $jar_count -gt 1 ]; then
  echo "More than one jar found, don't know which one to deploy. Exiting"
  exit 1
fi

# Put some useful output properties
JAR_FILE=`find ./target -type f -name *.jar`
BUILD_DATE=`date`

echo "JAR_FILE=${JAR_FILE}" >> "${propsFile}"
echo "BUILD_DATE=${BUILD_DATE}" >> "${propsFile}"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/target/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

#find ${ROOT_FOLDER}/${REPO_RESOURCE}/target -type f -name *.jar -exec cp "{}" package-output/attendee-service.jar \;

echo "Done packaging"
