#!/bin/bash

source tests/helper.sh

export WERCKER_SLACK_NOTIFY_SUBDOMAIN="wercker"
export WERCKER_SLACK_NOTIFY_TOKEN="$1"
export WERCKER_SLACK_NOTIFY_CHANNEL="productz"
export WERCKER_STEP_TEMP=/tmp
export FATAL_MESSAGE="Could not find specified channel for subdomain/token."
export FATAL_CALLED="false"

source run.sh

if [ "$FATAL_CALLED" = "false" ]; then
    echo "Error: fatal is not called."
    exit 1
fi
