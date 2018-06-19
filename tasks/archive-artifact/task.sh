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
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Archive Artifact ---"

POM_FILE="pom.xml"

# Checks version is ok with branchname
checkversion="$(checkVersion $CURRENT_BRANCH $POM_FILE)"
echo "CheckVersion result=${checkversion}"

# Check tag exists
tagexists="$(tagExists ${POM_FILE})"
echo "TagExists result=${tagexists}"

if [[ $checkversion = "true" ]]
then
    cp ${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE} .
 
    git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
    git config --global http.sslVerify false
    git config --global user.name "${GIT_NAME}"
    git config --global user.email "${GIT_EMAIL}"
    
    if [[ $tagexists = "true" ]]
    then  
      # Calculate next release based on tags
      PATCH_LEVEL=$(expr `git tag | grep '${CURRENT_BRANCH}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)
      NEXT_RELEASE=${CURRENT_BRANCH}.${PATCH_LEVEL}
      echo "Calculated next release: ${NEXT_RELEASE}"

      echo "WARN: The software is already tagged with this release"
      NEW_POM_VERSION="${NEXT_RELEASE}-SNAPSHOT"
      NEW_POM_FILE="${POM_FILE}.new"
      python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-version-pom.py ${POM_FILE} ${NEW_POM_FILE} ${NEW_POM_VERSION}
      mv $NEW_POM_FILE $POM_FILE
      
      echo "WARN: Patched pom version with value ${NEW_POM_VERSION}"
      git commit -a -m "[ci skip] Changed pom version from ${POM_VERSION} to ${NEW_POM_VERSION}"
    fi

    git checkout -f ${CURRENT_BRANCH}

    mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE} -Dsonar.branch=${SONAR_BRANCH}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE} -DscmCommentPrefix="[ci skip]"

    #mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Dmaven.wagon.http.ssl.ignore.validity.dates=true -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Djavax.net.ssl.trustStore=${TRUSTSTORE} -Dsonar.branch=${SONAR_BRANCH}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE} -DscmCommentPrefix="[ci skip]" -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true

    #mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE} -Dsonar.branch=${SONAR_BRANCH}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Dmaven.test.skip=true -DskipITs -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -DscmCommentPrefix="[ci skip]" ${BUILD_OPTIONS}
    
    # Maven release perform
    #mvn --batch-mode release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE} -Dsonar.branch=${SONAR_BRANCH}" -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUSTSTORE_FILE}"

    #echo "maven release:perform"
    #mvn --batch-mode release:perform -Dusername=${USERNAME} -Dpassword=${PASSWORD} -DskipTests=true ${BUILD_OPTIONS}
    
else
    POM_VERSION="$(getPomVersion $POM_FILE)"
    echo "ERROR: Pom Version ${POM_VERSION} does not match release name ${CURRENT_BRANCH}"
    exit 1
fi

echo "--- Archive Artifact ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
