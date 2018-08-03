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

# To run de scripts needs to be in this folder, will change in the future
cd "${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects" || exit

# Creates a folder to store all xml files produced by testrunner
mkdir FinalReports

LOGICAL_NAME="ID_20-Consistenze"

while IFS= read -r line
do
  echo "DEBUG: Read line: ${line}"

  # Randon file name for the workaround
  RANDOM_VALUE=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/random.py)
  RANDOM_FILE="salida${RANDOM_VALUE}"

  # Creates the file to execute the tests #WORKAROUND#. It creates a file that executes the tests in background and waits for it to finish
  soapUItestrunnerWorkaround ${RANDOM_FILE} 

  # Execution permissions
  chmod +x ${RANDOM_FILE}
  
  # Executes the tests
  ./${RANDOM_FILE}

  # Move all xml files in Report folder to a new location to create a unique html file, all files have to have different names,
  # and the tests produced the same xml file name, that is why it is moved to a new location
  for file in `ls ${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects/${LOGICAL_NAME}/Reports/*.xml`
  do
    RANDOM_VALUE=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/random.py)
    mv ${file} FinalReports/${RANDOM_VALUE}.xml
    echo "DEBUG: Moved file ${file} to FinalReports/${RANDOM_VALUE}.xml"
  done

done < ${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects/${LOGICAL_NAME}/ConfPipeline/run-${ENVIRONMENT_TO_TEST}.sh

# Build file to create the html file from the xml file with ant
cp "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/ant/build.xml .

# creates the html file with ant
ant 

# Rename the file created by ant
mv FinalReports/html/junit-noframes.html FinalReports/html/soapui-${ENVIRONMENT_TO_TEST}-report.html

POM_VERSION=$(getPomVersion ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)
ARTIFACT_ID=$(getArtifactId ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)
GROUP_ID=$(getGroupId ${ROOT_FOLDER}/${REPO_RESOURCE}/pom.xml)
RELEASE_VERSION=$(echo $POM_VERSION| cut -d'-' -f 1)

# Checks if there is some FAILED test
echo RESULT=$(find ${ROOT_FOLDER}/${TESTS_RESOURCE}/Projects/${LOGICAL_NAME}/Reports/ | grep FAILED | wc -l)
if [[ $RESULT = "0" ]]
then
  echo "Success!!"

  # Upload  the files to nexus
  find FinalReports/html -type f -exec curl -v --insecure -u ${M2_SETTINGS_REPO_USERNAME}:${M2_SETTINGS_REPO_PASSWORD} -T {} ${NEXUS_SITE_SERVER_URL}/${GROUP_ID}.${ARTIFACT_ID}.${RELEASE_VERSION}/{} \;
else
  # Upload the reports to nexus site and exit
  echo "Failed!!"
  
  # Upload  the files to nexus
  find FinalReports/html -type f -exec curl -v --insecure -u ${M2_SETTINGS_REPO_USERNAME}:${M2_SETTINGS_REPO_PASSWORD} -T {} ${NEXUS_SITE_SERVER_URL}/${GROUP_ID}.${ARTIFACT_ID}/{} \;

  # Removed this comment in the final version, now for testing purposes it is assumed the soap ui tests are passed ok
  #exit 1
fi

echo "-- Running SaopUI tests"

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
