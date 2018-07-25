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

cd Projects/consistenze

nohup /opt/SoapUI/bin/testrunner.sh -s"consistenze TestSuite" -r -a -j -J -GAmbiente=COLLEVO -f./Reports ./ID_20_Consistenze-soapui-project.xml &
PROC_ID=$!

while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    echo "PROCESS IS RUNNING"
    sleep 5
done
echo "PROCESS TERMINATED"

ls ./Reports

echo "-- Running SaopUI tests"

# Adding values to keyvalout
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
