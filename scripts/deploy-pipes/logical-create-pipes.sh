#!/bin/bash

source ./concourse-logical-params.sh

PIPELINE_DEPLOY_YML=../../pipeline-logical-microservice/pipeline-deploy.yml
PIPELINE_RELEASE_COLL_CONSOLIDATO_YML=../../pipeline-logical-microservice/pipeline-logical-release-coll-consolidato.yml
PIPELINE_RELEASE_COLL_EVOLUTIVO_YML=../../pipeline-logical-microservice/pipeline-logical-release-coll-evolutivo.yml
PIPELINE_SYSTEM_TEST=../../pipeline-logical-microservice/pipeline-logical-system-test.yml

function deployToEnviroment(){
  DEV=$1
  INPUT_APP_NAME=$2
  INPUT_APP_BRANCH=$3
  INPUT_PREFIX=$4

  sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-micros\/${INPUT_APP_NAME}.git/" logical-params-template-deploy-pipe.yml > params-logical-1-${INPUT_APP_NAME}.yml
  sed "s/app-branch: #APPS_BRANCH#/app-branch: ${INPUT_APP_BRANCH}/" params-logical-1-${INPUT_APP_NAME}.yml > params-logical-2-${INPUT_APP_NAME}.yml
  sed "s/environment-to-deploy: #ENV_TO_DEPLOY#/environment-to-deploy: ${DEV}/" params-logical-2-${INPUT_APP_NAME}.yml > params-logical-${INPUT_APP_NAME}.yml

  PIPELINE_NAME=${DEV}-${INPUT_PREFIX}-${INPUT_APP_NAME}

  fly -t automate sp -p ${PIPELINE_NAME} -c "${PIPELINE_DEPLOY_YML}" -l params-logical-${INPUT_APP_NAME}.yml -n

  rm params-logical-${INPUT_APP_NAME}.yml
  rm params-logical-1-${INPUT_APP_NAME}.yml
  rm params-logical-2-${INPUT_APP_NAME}.yml
}

function releasePipeline(){
  INPUT_APP_NAME=$1
  INPUT_APP_BRANCH=$2
  PIPE_PARAMS=$3
  PIPE_URL=$4
  PREFIX_PIPE_NAME=$5

  sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-micros\/${INPUT_APP_NAME}.git/" ${PIPE_PARAMS} > params-logical-1-${INPUT_APP_NAME}.yml
  sed "s/app-branch: #APPS_BRANCH#/app-branch: ${INPUT_APP_BRANCH}/" params-logical-1-${INPUT_APP_NAME}.yml > params-logical-2-${INPUT_APP_NAME}.yml
  sed "s/concourse-pipeline-name: #PIPELINE_COLL_EVOLUTIVO_NAME#/concourse-pipeline-name: release-collevo-${INPUT_APP_NAME}/" params-logical-2-${INPUT_APP_NAME}.yml > params-logical-3-${INPUT_APP_NAME}.yml
  sed "s/concourse-pipeline-name-consolidato: #PIPELINE_COLL_CONSOLIDATO_NAME#/concourse-pipeline-name-consolidato: release-collcon-${INPUT_APP_NAME}/" params-logical-3-${INPUT_APP_NAME}.yml > params-logical-${INPUT_APP_NAME}.yml

  PIPELINE_NAME=${PREFIX_PIPE_NAME}-${INPUT_APP_NAME}

  fly -t automate sp -p ${PIPELINE_NAME} -c "${PIPE_URL}" -l params-logical-${INPUT_APP_NAME}.yml -n

  rm params-logical-${INPUT_APP_NAME}.yml
  rm params-logical-1-${INPUT_APP_NAME}.yml
  rm params-logical-2-${INPUT_APP_NAME}.yml
  rm params-logical-3-${INPUT_APP_NAME}.yml
}

fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly -t automate sync

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH=$(echo ${app} | awk -F"@" '{print $2}')  
  APP_BRANCH_EVO=$(echo ${app} | awk -F"@" '{print $3}')

  deployToEnviroment "dev1" ${APP_NAME} ${APP_BRANCH} "collcon"
  deployToEnviroment "dev2" ${APP_NAME} ${APP_BRANCH} "collcon"
  deployToEnviroment "dev3" ${APP_NAME} ${APP_BRANCH} "collcon"
  deployToEnviroment "dev4" ${APP_NAME} ${APP_BRANCH} "collcon"
  deployToEnviroment "dev1" ${APP_NAME} ${APP_BRANCH_EVO} "collevo"
  deployToEnviroment "dev2" ${APP_NAME} ${APP_BRANCH_EVO} "collevo"
  deployToEnviroment "dev3" ${APP_NAME} ${APP_BRANCH_EVO} "collevo"
  deployToEnviroment "dev4" ${APP_NAME} ${APP_BRANCH_EVO} "collevo"

  releasePipeline ${APP_NAME} ${APP_BRANCH} "logical-params-template-release-coll-consolidato-pipe.yml" ${PIPELINE_RELEASE_COLL_CONSOLIDATO_YML} "release-collcon"
  releasePipeline ${APP_NAME} ${APP_BRANCH_EVO} "logical-params-template-release-coll-evolutivo-pipe.yml" ${PIPELINE_RELEASE_COLL_EVOLUTIVO_YML} "release-collevo"
  releasePipeline ${APP_NAME} ${APP_BRANCH} "logical-params-template-release-coll-consolidato-pipe.yml" ${PIPELINE_SYSTEM_TEST} "systemtest-collcon"
  releasePipeline ${APP_NAME} ${APP_BRANCH_EVO} "logical-params-template-release-coll-consolidato-pipe.yml" ${PIPELINE_SYSTEM_TEST} "systemtest-collevo"
done < "logical-apps"
