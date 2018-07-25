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
export OUTPUT_TESTS=outtests
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${TESTS_RESOURCE}" || exit

echo "-- Running SaopUI tests"

cd 

nohup /opt/SoapUI/bin/testrunner.sh -s"consistenze TestSuite" -r -a -j -J -GAmbiente=COLLEVO -f./Reports ./ID_20_Consistenze-soapui-project.xml &
PROC_ID=$!

while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    echo "Tests running ..."
    sleep 5
done
echo "Tests finished!!"

cp -r "${ROOT_FOLDER}/${TESTS_RESOURCE}"/Projects/consistenze/. "${ROOT_FOLDER}/${OUTPUT_TESTS}/"

echo RESULT=$(ls ./Reports/ | grep FAILED | wc -l)
if [[ $RESULT = "0" ]]
then
  echo "Success!!"
else
  echo "Failure!!"
  exit 1
fi

echo "-- Running SaopUI tests"

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
