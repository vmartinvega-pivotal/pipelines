#!/bin/bash

source ./concourse-physical-params.sh

programname=$0

function usage {
    # Format for the file
    # <app-name>@branch
    #
    echo "usage: $programname [app name] [release branch]"
    exit 1
}

if [ "$#" -lt 2 ]; then
  usage
fi

PIPELINE_RELEASE_YML=../../pipeline-physical-microservice/pipeline-build.yml

APP_NAME=$1
APP_BRANCH=$2

sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-apps\/${APP_NAME}.git/" physical-params-template-build-pipe.yml > params-build-1-${APP_NAME}.yml
sed "s/app-branch: #APPS_BRANCH#/app-branch: ${APP_BRANCH}/" params-build-1-${APP_NAME}.yml > params-build-${APP_NAME}.yml
fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly -t automate sync
 
PIPELINE_RELEASE_NAME=release-${APP_NAME}-${APP_BRANCH}

fly -t automate sp -p ${PIPELINE_RELEASE_NAME} -c "${PIPELINE_RELEASE_YML}" -l params-build-${APP_NAME}.yml -n
rm params-build-${APP_NAME}.yml
rm params-build-1-${APP_NAME}.yml

