#!/bin/bash

PIPELINE_NAME="pipeline-build.yml"
ALIAS="local"
CREDENTIALS="credentials-build.yml"

fly -t "${ALIAS}" sp -p "${PIPELINE_NAME}" -c pipeline-build.yml -l "${CREDENTIALS}" -n
