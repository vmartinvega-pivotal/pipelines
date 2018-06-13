#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

function cfLogin(){
  cf api $PWS_API --skip-ssl-validation

  cf login -u $PWS_USER -p $PWS_PWD -o "$PWS_ORG" -s "$PWS_SPACE"
}

function cfSCDFDeploy(){
#TODO: creates a service instance of scdf and waits for it to be created, then gets the the url and put it in PASSED_SCDF_SERVER_URL

export PASSED_SCDF_SERVER_URL="hppt://192.168.177.141:9393"
}
