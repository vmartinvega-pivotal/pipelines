#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export TOOLS_RESOURCE=tools

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Clean Environment ---"

function deleteApps(){
  APP_TYPE=$1

  for app in `curl -s ''${INPUT_SCDF_SERVER_URL}'/apps?type='${APP_TYPE}'' -i -H 'Accept: application/json' | tail -n +7 | python -m json.tool | jq '._embedded.appRegistrationResourceList[]._links.self.href' | sed -e 's/^"//' -e 's/"$//'`
  do 
    echo "Deleting app: " $app
    curl ''${app}'' -i -X DELETE
  done
}

# Remove all streams
#curl ''${SCDF_SERVER_URL}'/streams/definitions' -i -X DELETE

# Remove all apps
#deleteApps 'sink'
#deleteApps 'source'
#deleteApps 'processor'

cfLogin
getPCFUrls

echo "--- Clean Environment ---"
echo ""

echo "Done!!"
