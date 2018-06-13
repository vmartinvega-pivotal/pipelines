#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export TRUSTSTORE_FILE="${ROOT_FOLDER}/${TOOLS_RESOURCE}/settings/${TRUSTSTORE}"

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"
touch ${propsFile}

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Archive Artifact ---"

POM_FILE="pom.xml"

# Checks version is ok with branchname
checkversion="$(checkVersion $CURRENT_BRANCH $POM_FILE)"
echo "CheckVersion result=${checkversion}"

# Check tag exists
tagexists="$(tagExists ${POM_FILE})"
echo "TagExists result=${tagexists}"

# Calculate next release based on tags
PATCH_LEVEL=$(expr `git tag | grep '${CURRENT_BRANCH}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)
NEXT_RELEASE=${CURRENT_BRANCH}.${PATCH_LEVEL}
echo "Calculated next release: ${NEXT_RELEASE}"

if [[ $checkversion = "true" ]]
then
    if [[ $tagexists = "true" ]]
    then  
      #    echo "new line" >> some-file.txt

       #   git add .

      echo "WARN: The software is already tagged with this release"
      NEW_POM_VERSION="${NEXT_RELEASE}-SNAPSHOT"
      NEW_POM_FILE="${POM_FILE}.new"
      python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-version-pom.py ${POM_FILE} ${NEW_POM_FILE} ${NEW_POM_VERSION}
      mv $NEW_POM_FILE $POM_FILE

      # git config --global user.name "${GIT_NAME}"
      # git config --global user.email "${GIT_EMAIL}"
      
      echo "WARN: Patched pom version with value ${NEW_POM_VERSION}"
      #git -c http.sslVerify=false -c http.sslKey=${HOME}/.gitprivatekey/privatekey commit -a -m "Changed pom version from ${POM_VERSION} to ${NEW_POM_VERSION}"
      #git commit -a -m "Changed pom version from ${POM_VERSION} to ${NEW_POM_VERSION}"
    fi

    # Maven release prepare
    #mvn --batch-mode release:clean release:prepare -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE}"
    mvn --batch-mode release:clean release:prepare -Dusername=${USERNAME} -Dpassword=${PASSWORD} ${BUILD_OPTIONS}
    echo "maven prepare"

    # Maven release perform
    #mvn -s $MAVEN_SETTINGS --batch-mode release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Dsonar.branch=${SONAR_BRANCH}" -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE}"
    echo "maven release"
else
    POM_VERSION="$(getPomVersion $POM_FILE)"
    echo "ERROR: Pom Version ${POM_VERSION} does not match release name ${CURRENT_BRANCH}"
    exit 1
fi

echo "--- Archive Artifact ---"
echo ""

# Adding values to keyvalout
BUILD_DATE=`date`
echo "ARCHIVE_DATE=${BUILD_DATE}" >> "${propsFile}"

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
