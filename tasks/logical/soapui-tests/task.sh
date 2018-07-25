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

cd "${ROOT_FOLDER}/${TESTS_RESOURCE}" || exit

echo "-- Running SaopUI tests"

cd Projects/bucket

nohup /opt/SoapUI/bin/testrunner.sh -s"bucket - TestSuite (v1)" -r -a -j -J -GAmbiente=COLLEVO -f./Reports ./bucket-soapui-project.xml &
PROC_ID=$!

while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    echo "Tests running ..."
    sleep 5
done
echo "Tests finished!!"

echo RESULT=$(ls ./Reports/ | grep FAILED | wc -l)
if [[ $RESULT = "0" ]]
then
  echo "Success!!"
else
  echo "Failure!!"
  
  cp "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/ant/build.xml .

  ant
  
  POM_VERSION=$(getPomVersion ${ROOT_FOLDER}/${TESTS_RESOURCE}/pom.xml)
  ARTIFACT_ID=$(getArtifactId ${ROOT_FOLDER}/${TESTS_RESOURCE}/pom.xml)

  mv Reports/html/unit-noframes.html Reports/html/${POM_VERSION}.html 
  
  find Reports/html -type f -exec curl -v --insecure -u devops-sdp:zxcdsa011 -T {} https://nexus-sdp.telecomitalia.local/nexus/repository/site/com.tim.sdp.${ARTIFACT_ID}/{} \;
  exit 1
fi

echo "-- Running SaopUI tests"

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
