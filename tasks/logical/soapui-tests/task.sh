#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export TESTS_RESOURCE=tests
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

echo "-- Running SaopUI tests"

cd "${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects" || exit

while IFS= read -r line
do
  echo eval "nohup ${line} &"
  PROC_ID=$!
  while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    echo "Tests running ..."
    sleep 5
  done
  echo "Tests finished!!"
done < ${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects/ID_20-Consistenze/ConfPipeline/run-collevo.sh

echo RESULT=$(ls ${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects/ID_20-Consistenze/Reports/ | grep FAILED | wc -l)
if [[ $RESULT = "0" ]]
then
  echo "Success!!"
else
  # Upload the reports to nexus site and exit
  echo "Failure!!"
  
  # Build file to create the html file from the xml file with ant
  cp "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/ant/build.xml .

  # Run ant to create the html file
  ant
  
  POM_VERSION=$(getPomVersion ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)
  ARTIFACT_ID=$(getArtifactId ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)
  GROUP_ID=$(getGroupId ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)

  # Rename the file created by ant
  mv Reports/html/junit-noframes.html Reports/html/${POM_VERSION}.html 
  
  # Upload  the files to nexus
  find Reports/html -type f -exec curl -v --insecure -u ${M2_SETTINGS_REPO_USERNAME}:${M2_SETTINGS_REPO_PASSWORD} -T {} https://${M2_SETTINGS_REPO_SITE_URL}/${GROUP_ID}.${ARTIFACT_ID}/{} \;

  exit 1
fi

echo "-- Running SaopUI tests"

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
