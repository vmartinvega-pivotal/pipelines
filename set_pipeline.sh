#!/bin/bash

PIPELINE_NAME="$1"
ALIAS="local"
CREDENTIALS="$2"
PIPELINE_YML="$3"

fly -t "${ALIAS}" sp -p "${PIPELINE_NAME}" -c "${PIPELINE_YML}" -l "${CREDENTIALS}" -n
