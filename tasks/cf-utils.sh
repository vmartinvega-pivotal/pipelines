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
  cf api $PWS_API --skip-ssl-validation

  cf login -u $PWS_USER -p $PWS_PWD -o "$PWS_ORG" -s "$PWS_SPACE"
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
