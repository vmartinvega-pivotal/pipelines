#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

function getUrlArtifact(){
  USERNAME=$1 # devops-sdp
  PASSWORD=$2 # zxcdsa011
  REPOSITORY=$3 # maven-releases
  GROUP=$4 # com.tim.sdp
  NAME=$5 # logical-microservice
  VERSION=$6 # 1.0.113

  echo insecure >> ~/.curlrc

  RESULT=$(curl -u ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' 'https://nexus-sdp.telecomitalia.local/nexus/service/siesta/rest/beta/search?repository='${REPOSITORY}'&group='${GROUP}'&name='${NAME}'&version='${VERSION}'' | jq '.items[].assets[].downloadUrl' | grep jar\" | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}
}

# Converts a string to lower case
function toLowerCase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Gets the artifactid tag from a POM file
# Arguments:
# 1 - Pom file
#
# Result string: artifactid
#
function getArtifactId(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py $1 "artifact")
}

function randomName(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/random.py)
}

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
  POM_VERSION="$(getPomVersion $2)"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/check-version.py "\d+\.\d+\.\d+" ${VERSION} $1)
}

# Checks there is a tag on git for the current branch that ends with the version extracted from the POM version
# Arguments:
# 1 - Pom file
#
# Result string: true/false
#
function tagExists(){
  POM_VERSION="$(getPomVersion $1)"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  TAG=$(git tag | grep '${VERSION}' || echo 'OK')
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/tag-exists.py ${TAG} ${VERSION})
}
