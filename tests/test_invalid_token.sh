#!/bin/bash

source tests/helper.sh

export WERCKER_SLACK_NOTIFY_SUBDOMAIN="wercker"
export WERCKER_SLACK_NOTIFY_TOKEN="${1}z"
export WERCKER_SLACK_NOTIFY_CHANNEL="product"
export WERCKER_STEP_TEMP=/tmp
export FATAL_MESSAGE="Subdomain or token not found."
export FATAL_CALLED="false"
source run.sh

if [ "$FATAL_CALLED" = "false" ]; then
    echo "Error: fatal is not called."
    exit 1
fi
