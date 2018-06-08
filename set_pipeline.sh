#!/bin/bash

PIPELINE_NAME="$1"
ALIAS="local"
CREDENTIALS="credentials-build.yml"
PIPELINE_YML="$2"

fly -t "${ALIAS}" sp -p "${PIPELINE_NAME}" -c "${PIPELINE_YML}" -l "${CREDENTIALS}" -n
