#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

# Reads a file.properties as the first argument and add it as a environment variable
function exportKeyValPropertiesForDeploying() {
	props=$1
	echo "Props are in [${props}]"
	if [ -f "${props}" ]
	then
	  echo "Reading passed key values"
	  while IFS= read -r var
	  do
	    if [ ! -z "${var}" ]
	    then
	      echo "Adding: ${var}"
	      export "$var"
	    fi
	  done < "${props}"
	fi
}

function cfLogin(){
  PWS_API=$1
  PWS_USER=$2
  PWS_PWD=$3
  PWS_ORG=$4
  PWS_SPACE=$5

  cf login -a "${PWS_API}" --skip-ssl-validation -u "${PWS_USER}" -p "${PWS_PWD}" -o "${PWS_ORG}" -s "${PWS_SPACE}"
}

# This function export a variable PASSED_APPS_URL with the URL to access all applications for an organization and space inside PCF
function getAppsUrl(){
  ORGANIZATION_NAME=$1
  SPACE_NAME=$2

  ORGANIZATIONS=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${ORGANIZATION_NAME}'" ) | .entity.spaces_url' | wc -l)

  if [[ $ORGANIZATIONS -gt "1" ]]
  then
    echo "ERROR: Found more than 1 organizations with name ${ORGANIZATION_NAME}!!!!"
    exit 1
  fi

  SPACES_URL=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${ORGANIZATION_NAME}'" ) | .entity.spaces_url' | sed -e 's/^"//' -e 's/"$//')

  echo "DEBUG: Spaces Url: ${SPACES_URL} for organization ${ORGANIZATION_NAME}"

  SPACES=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${SPACE_NAME}'" ) | .entity.apps_url' | wc -l)

  if [[ $SPACES -gt "1" ]]
  then
    echo "ERROR: Found more than 1 space with name ${SPACE_NAME} in the organization ${ORGANIZATION_NAME}!!!!"
    exit 1
  fi

  APPS_URL=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.name == "'${SPACE_NAME}'") | .entity.apps_url' | sed -e 's/^"//' -e 's/"$//')

  echo "DEBUG: Apps Url: ${APPS_URL}"

  export PASSED_APPS_URL=${APPS_URL}
}

function cfSCDFDeploy(){
  
  #TODO: creates a service instance of scdf and waits for it to be created, then gets the the url and put it in PASSED_SCDF_SERVER_URL
  if [ -z "${SCDF_SERVER_URL}" ]; then
    echo "SCDF_SERVER_URL is unset or set to the empty string, creating a new instance for scdf"
    export PASSED_SCDF_SERVER_URL="TODO:"
  else
    export PASSED_SCDF_SERVER_URL=${SCDF_SERVER_URL}
  fi
}
