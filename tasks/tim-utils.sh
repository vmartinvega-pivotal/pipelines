#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

function getPythonFile(){
  if [[ $DEBUG_LOCAL = "true" ]]
  then
    echo "../../python/parse-pom.py"
  else
    echo "${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/$1"
  fi
}

# Gets the version tag from a POM file
# Arguments:
# 1 - Pom file
#
# Result string: pom version
#
function getPomVersion(){
  PYTHON_FILE="$(getPythonFile parse-pom.py)"
  echo $(python ${PYTHON_FILE} $1 "version")
}

# Checks if the branch name starts with the version extracted from the POM version
# Arguments:
# 1 - Pom File
# 2 - Branch name
#
# Result string: true / false
#
function checkVersion(){
  POM_VERSION="$(getPomVersion $1)"
  PYTHON_FILE="$(getPythonFile check-version.py)"
  echo $(python ${PYTHON_FILE} "\d+\.\d+\.\d+" $2 ${POM_VERSION})
}

# Checks there is a tag on git for the current branch that ends with the version extracted from the POM version
# Arguments:
# 1 - Pom file
#
# Result string: true/false
#
function tagExists(){
  POM_VERSION="$(getPomVersion $1)"
  PYTHON_FILE="$(getPythonFile regex-match.py)"
  VERSION=$(python ${PYTHON_FILE} "\d+\.\d+\.\d+" ${POM_VERSION} "find" 0)
  TAG=$(git tag | grep '${VERSION}' || echo 'OK')
  PYTHON_FILE="$(getPythonFile tag-exists.py)"
  echo $(python ${PYTHON_FILE} ${TAG} ${VERSION})
}
