#!/bin/bash

source ./concourse-physical-params.sh

PIPELINE_YML=../../pipeline-physical-microservice/pipeline-build.yml

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH=$(echo ${app} | awk -F"@" '{print $2}')  

  sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-apps\/${APP_NAME}.git/" physical-params-template-build-pipe.yml > params-build-1-${APP_NAME}.yml
  sed "s/app-branch: #APPS_BRANCH#/app-branch: ${APP_BRANCH}/" params-build-1-${APP_NAME}.yml > params-build-${APP_NAME}.yml
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync
 
  PIPELINE_NAME=release-${APP_NAME}

  fly -t automate sp -p ${PIPELINE_NAME} -c "${PIPELINE_YML}" -l params-build-${APP_NAME}.yml -n
  rm params-build-${APP_NAME}.yml
  rm params-build-1-${APP_NAME}.yml
done < "physical-apps"
