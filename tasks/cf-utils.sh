#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

function cfTest(){
  cf api $PWS_API --skip-ssl-validation

  cf login -u $PWS_USER -p $PWS_PWD -o "$PWS_ORG" -s "$PWS_SPACE"

  cf apps
}
