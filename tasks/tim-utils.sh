#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

# Gets the version tag from a POM file
# Arguments:
# 1 - Pom file
#
# Result string: pom version
#
function getPomVersion(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py $1 "version")
}

# Gets version from pom version based on a regular expression
# Arguments:
# 2 - Pom version
#
# Result string: version
#
function getVersionFromPomVersion(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/regex-match.py "\d+\.\d+\.\d+" $1 "find" 0)
}

# Checks if the branch name starts with the version extracted from the POM version
# Arguments:
# 1 - Branch name
# 2 - Pom file
#
# Result string: true / false
#
function checkVersion(){
  echo ""
  echo "-- function checkVersion --"
  echo "arg1 (Branch Name): $1"
  echo "arg2 (Pom File): $2"
  echo ""
  POM_VERSION="$(getPomVersion $2)"
  echo "checkVersion step1 - POM_VERSION: ${POM_VERSION}"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  echo "checkVersion step2 - VERSION: ${VERSION}"
  result=$(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/check-version.py "\d+\.\d+\.\d+" ${VERSION} $1)
  echo "checkVersion result: ${result}"
  echo "-- function checkVersion --"
  echo ""
  if [[ $result = "true" ]]
  then
    true
  else
    false
  fi
}

# Checks there is a tag on git for the current branch that ends with the version extracted from the POM version
# Arguments:
# 1 - Pom file
#
# Result string: true/false
#
function tagExists(){
  echo "-- function tagExists --"
  echo "arg1 (Pom File): $1"
  echo ""
  POM_VERSION="$(getPomVersion $1)"
  echo "tagExists step1 - POM_VERSION: ${POM_VERSION}"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  echo "tagExists step2 - VERSION: ${VERSION}"
  TAG=$(git tag | grep '${VERSION}' || echo 'OK')
  echo "tagExists step3 - TAG: ${TAG}"
  result=$(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/tag-exists.py ${TAG} ${VERSION})
  echo "tagExists result: ${result}"
  echo "-- function tagExists --"
  echo ""
  if [[ $result = "true" ]]
  then
    true
  else
    false
  fi
}
