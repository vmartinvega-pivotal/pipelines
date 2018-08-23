#!/bin/bash

source ./concourse-params.sh

PIPELINE_YML=../../pipeline-logical-microservice/pipeline-deploy.yml

function deployToEnviroment(){
  DEV=$1
  APP_NAME=$2
  APP_BRANCH=$3

  sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-micros\/${APP_NAME}.git/" logical-params-template-deploy-pipe.yml > params-logical-1-${APP_NAME}.yml
  sed "s/app-branch: #APPS_BRANCH#/app-branch: ${APP_BRANCH}/" params-logical-1-${APP_NAME}.yml > params-logical-2-${APP_NAME}.yml
  sed "s/environment-to-deploy: #ENV_TO_DEPLOY#/environment-to-deploy: ${DEV}/" params-logical-2-${APP_NAME}.yml > params-logical-${APP_NAME}.yml
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync
  
  PIPELINE_NAME=${DEV}-deploy-${APP_NAME}

  fly -t automate sp -p ${PIPELINE_NAME} -c "${PIPELINE_YML}" -l params-logical-${APP_NAME}.yml -n
  rm params-logical-${APP_NAME}.yml
  rm params-logical-1-${APP_NAME}.yml
  rm params-logical-2-${APP_NAME}.yml
}

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH=$(echo ${app} | awk -F"@" '{print $2}')  

  deployToEnviroment "dev1" ${APP_NAME} ${APP_BRANCH}
  deployToEnviroment "dev2" ${APP_NAME} ${APP_BRANCH}
  deployToEnviroment "dev3" ${APP_NAME} ${APP_BRANCH}
  deployToEnviroment "dev4" ${APP_NAME} ${APP_BRANCH}
  
done < "logical-apps"
