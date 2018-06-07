#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export KEYVALOUTPUT_RESOURCE=keyvalout

propsDir="${ROOT_FOLDER}/${KEYVALOUTPUT_RESOURCE}"
propsFile="${propsDir}/keyval.properties"

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "Extracting POM usefull info"

#TODO: Comprobar que no es nulo el resultado, con lo que no lo habria encontrado o se produce alguna exception en cuyo caso hay que abortar
POM_VERSION=`python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}version")'`
POM_GROUPID=`python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}groupId")'`
POM_ARTIFACTID=`python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}artifactId")'`

echo "POM_VERSION=${POM_VERSION}" >> "${propsFile}"
echo "POM_GROUPID=${POM_GROUPID}" >> "${propsFile}"
echo "POM_ARTIFACTID=${POM_ARTIFACTID}" >> "${propsFile}"

echo "Done extraction!!"
