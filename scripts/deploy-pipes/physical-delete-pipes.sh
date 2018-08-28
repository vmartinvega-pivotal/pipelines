#!/bin/bash

source ./concourse-physical-params.sh

programname=$0

function usage {
    # Format for the file
    # <app-name>@branch
    #
    echo "usage: $programname [apps file]"
    exit 1
}

if [ "$#" -lt 1 ]; then
  usage
fi

INPUT_FILE=$1

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH=$(echo ${app} | awk -F"@" '{print $2}')

  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync

  PIPELINE_RELEASE_NAME=release-${APP_NAME}-${APP_BRANCH}

  fly -t automate destroy-pipeline -p ${PIPELINE_RELEASE_NAME} -n
done < "${INPUT_FILE}"
