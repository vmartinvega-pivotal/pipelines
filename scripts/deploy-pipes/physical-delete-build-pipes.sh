#!/bin/bash

source ./concourse-physical-params.sh

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync

  PIPELINE_NAME=release-${APP_NAME}

  fly -t automate destroy-pipeline -p ${PIPELINE_NAME} -n
done < "physical-apps"
