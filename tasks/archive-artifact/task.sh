#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export DEBUG_LOCAL="false"
export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export TRUSTSTORE_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/settings/${TRUSTSTORE}"

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"

echo "Generating settings.xml / gradle properties for Maven in local m2"
# shellcheck source=/dev/null
#source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/generate-settings.sh

echo "--- Task Params ---"
echo "BUILD_OPTIONS: [${BUILD_OPTIONS}]"
echo "SONAR_BRANCH: [${SONAR_BRANCH}]"
echo "TRUSTSTORE: [${TRUSTSTORE}]"
echo "TRUSTSTORE_FILE: [${TRUSTSTORE_FILE}]"
echo "USERNAME: [${USERNAME}]"
echo "PASSWORD: [...]"
echo "BRANCHNAME: [${BRANCHNAME}]"
echo "SONAR_BRANCH: [${SONAR_BRANCH}]"
echo "--- Task Params ---"
echo ""

if [[ $DEBUG_LOCAL = "false" ]]
then
  cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit
fi

echo "--- Archive Artifact ---"

POM_FILE="pom.xml"

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
  POM_VERSION="$(getPomVersion $2)"
  PYTHON_FILE="$(getPythonFile check-version.py)"
  echo $(python ${PYTHON_FILE} "\d+\.\d+\.\d+" $1 ${POM_VERSION})
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

# Checks version is ok with branchname
checkversion="$(checkVersion $BRANCHNAME $POM_FILE)"
echo "CheckVersion=${checkversion}"

# Calculate next release based on tags
PATCH_LEVEL=$(expr `git tag | grep '${BRANCHNAME}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)
NEXT_RELEASE=${BRANCHNAME}.${PATCH_LEVEL}
echo "Calculated next release: ${NEXT_RELEASE}"

# Check tag exists
tagexists="$(tagExists ${POM_FILE})"
echo "tagexists=${tagexists}"

if [[ $checkversion = "true" ]]
then
    if [[ $tagexists = "true" ]]
    then
      

      cd repo-modified
      #    echo "new line" >> some-file.txt

       #   git add .

        #  git config --global user.name "YOUR NAME"
         # git config --global user.email "YOUR EMAIL ADDRESS"

         # git commit -m "Changed some-file.txt"

      echo "WARN: The software is already tagged with this release"
      NEW_POM_VERSION="${NEXT_RELEASE}-SNAPSHOT"
      NEW_POM_FILE="${POM_FILE}.new"
      PYTHON_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-version-pom.py"
      if [[ $DEBUG_LOCAL = "true" ]]
      then
        PYTHON_FILE="../../python/modify-version-pom.py"
      fi
      $(python ${PYTHON_FILE} ${POM_FILE} ${NEW_POM_FILE} ${NEW_POM_VERSION})
      echo "WARN: Patched pom version with value ${NEW_POM_VERSION}"
      #git commit -a -m "Changed pom version from ${POM_VERSION} to ${NEW_POM_VERSION}"
    fi

    # Maven release prepare
    #mvn -s ${MAVEN_SETTINGS_FILE} --batch-mode release:clean release:prepare -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE}"
    echo "maven prepare"

    # Maven release perform
    #mvn -s $MAVEN_SETTINGS --batch-mode release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Dsonar.branch=${SONAR_BRANCH}" -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE}"
    echo "maven release"
else
    echo "ERROR: Pom Version ${POM_VERSION} does not match release name ${BRANCHNAME}"
    exit 1
fi

echo "--- Archive Artifact ---"
echo ""

# Adding values to keyvalout
BUILD_DATE=`date`
echo "ARCHIVE_DATE=${BUILD_DATE}" >> "${propsFile}"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
