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
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Prepare Release ---"

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

mvn --batch-mode release:clean release:prepare -DdryRun=true -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments=" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

cp pom.xml.next pom.xml.backup

mvn release:clean -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

git add pom.xml
  
git commit -m "[ci skip] Adding pom.xml resolved"

#git push https://andrea.lambruschini:zxcdsa01\!@gitlab-sdp.telecomitalia.local/demodevops/consistenze-id20.git --all
#git push https://${USERNAME}:${PASSWORD}@gitlab-sdp.telecomitalia.local/demodevops/consistenze-id20.git

#echo "***************************************Push done!!"

#mvn --batch-mode release:clean release:prepare -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}  -DscmCommentPrefix="[ci skip]" 

#echo "***************************************Prepared release!!"

#mv pom.xml.backup pom.xml

#git add pom.xml

#git push https://andrea.lambruschini:zxcdsa01\!@gitlab-sdp.telecomitalia.local/demodevops/consistenze-id20.git --all
#git push https://${USERNAME}:${PASSWORD}@gitlab-sdp.telecomitalia.local/demodevops/consistenze-id20.git

#echo "***************************************Push done!!"

#mvn --batch-mode release:perform -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}  -DscmCommentPrefix="[ci skip]" 

#echo "--- Prepare Release ---"
#echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
