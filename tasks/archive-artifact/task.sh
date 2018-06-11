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
export MAVEN_SETTINGS_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/settings/${MAVEN_SETTINGS}"

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"

echo "--- Task Params ---"
echo "MAVEN_SETTINGS: [${MAVEN_SETTINGS}]"
echo "MAVEN_SETTINGS_FILE: [${MAVEN_SETTINGS_FILE}]"
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

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Archive Artifact ---"

REGEXP="\d+\.\d+\.\d+"
POM_FILE="pom.xml"
#BRANCHNAME="2.0"

# Extracts the POM version from file
PYTHON_PARSE_POM_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py"
if [[ $DEBUG_LOCAL = "true" ]]
then
  PYTHON_PARSE_POM_FILE="../../python/parse-pom.py"
fi
POM_VERSION=$(python ${PYTHON_PARSE_POM_FILE} $POM_FILE "version")
echo "POM_VERSION=${POM_VERSION}"

# Checks version is ok with branchname
PYTHON_CHECK_VERSION_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/check-version.py"
if [[ $DEBUG_LOCAL = "true" ]]
then
  PYTHON_CHECK_VERSION_FILE="../../python/check-version.py"
fi
checkversion=$(python ${PYTHON_CHECK_VERSION_FILE} $REGEXP $POM_VERSION $BRANCHNAME)
echo "CheckVersion result=${checkversion}"

# Calculate next release based on tags
PATCH_LEVEL=$(expr `git tag | grep '${BRANCHNAME}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)
NEXT_RELEASE=${BRANCHNAME}.${PATCH_LEVEL}
echo "Calculated next release: ${NEXT_RELEASE}"

# Check tag exists
PYTHON_REGEX_MATCH_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/regex-match.py"
if [[ $DEBUG_LOCAL = "true" ]]
then
  PYTHON_REGEX_MATCH_FILE="../../python/regex-match.py"
fi
VERSION=$(python ${PYTHON_REGEX_MATCH_FILE} $REGEXP $POM_VERSION "find" 0) 
echo "VERSION=${VERSION}"
TAG=$(git tag | grep '${VERSION}' || echo 'OK')
echo "Tag=${TAG}"

PYTHON_TAG_EXISTS_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/tag-exists.py"
if [[ $DEBUG_LOCAL = "true" ]]
then
  PYTHON_TAG_EXISTS_FILE="../../python/tag-exists.py"
fi
tagexists=$(python ${PYTHON_TAG_EXISTS_FILE} ${TAG} ${VERSION})
echo "TagExists result=${tagexists}"

if [[ $checkversion = "true" ]]
then
    if [[ $tagexists = "true" ]]
    then
      echo "WARN: The software is already tagged with this release"
      NEW_POM_VERSION="${NEXT_RELEASE}-SNAPSHOT"
      NEW_POM_FILE="${POM_FILE}.new"
      PYTHON_MODIFY_VERSION_POM_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-version-pom.py"
      if [[ $DEBUG_LOCAL = "true" ]]
      then
        PYTHON_MODIFY_VERSION_POM_FILE="../../python/modify-version-pom.py"
      fi
      $(python ${PYTHON_MODIFY_VERSION_POM_FILE} ${POM_FILE} ${NEW_POM_FILE} ${NEW_POM_VERSION})
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
