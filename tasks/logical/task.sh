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

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Logical Test ---"

POM_FILE="pom.xml"

chmod 777 ${TRUST_STORE_FILE}

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

# For insecure connections
# echo insecure >> ~/.curlrc

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Generate the app-descriptor for the microservice from the template
python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py ./dependencies.list ./app-descriptor-template.df app-descriptor.df dependencies.json

# TODO: if contains #VERSION abort!! Not all dependencies were resolved!!
#cat app-descriptor.df | grep '#VERSION' | wc -l

# If does not exist app-descriptor.df put it in place and push
if [ ! -f ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df ]; then
  cp app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}
  
  cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

  git checkout -f ${CURRENT_BRANCH}
  git add --all
  git commit -a -m "[ci skip] Adding app-descriptor.df for environment ${DEPLOYING_ENVIRONMENT}"
  git push https://${USERNAME}:${PASSWORD}@gitlab-sdp.telecomitalia.local/demodevops/logical-microservice

  # Maven release
  echo "Creating maven release!!"
  #mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -DscmCommentPrefix="[ci skip]"
else
  # Check if there are differencies
  echo "DEBUG: Checking for differencies..."
  MD51=$(md5sum app-descriptor.df | awk '{ print $1 }')
  MD52=$(md5sum ${ROOT_FOLDER}/${REPO_RESOURCE}/app-descriptor.df | awk '{ print $1 }')
  echo "DEBUG: MD51: ${MD51}"
  echo "DEBUG: MD52: ${MD52}"

  if [ "'${MD51}'" == "'${MD52}'" ]; then
    echo "DEBUG: There are not differencies with the old app-descriptor and the new one, skipping..."
  else
    echo "DEBUG: There are differencies with the old app-descriptor and the new one, creating a new release"

    mv app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}
  
    cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

    git checkout -f ${CURRENT_BRANCH}
    git add --all
    git commit -a -m "[ci skip] Replacing app-descriptor.df for environment ${DEPLOYING_ENVIRONMENT}, for a new version"
    git push https://${USERNAME}:${PASSWORD}@gitlab-sdp.telecomitalia.local/demodevops/logical-microservice

    # Maven release
    echo "Creating maven release!!"
    #mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -DscmCommentPrefix="[ci skip]"
  fi
fi

#mvn versions:revert -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# 
#mvn dependency:get -Dartifact=com.tim.sdp:sdp-demo-clienti:jar:1.0.137:sources -Djavax.net.ssl.trustStore=../sdp-demo-clienti/truststore.jks -Dtransitive=false

#mvn -s ../sdp-demo-clienti/settings.xml dependency:copy-dependencies -Dclassifier=sources -Djavax.net.ssl.trustStore=../sdp-demo-clienti/truststore.jks

#mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -DscmCommentPrefix="[ci skip]"

echo "--- Logical Test ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
