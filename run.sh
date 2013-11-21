#!/bin/bash

if [ ! -n "$WERCKER_SLACK_NOTIFY_SUBDOMAIN" ]; then
error 'Please specify the subdomain property'
  exit 1
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_TOKEN" ]; then
error 'Please specify token property'
  exit 1
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_CHANNEL" ]; then
error 'Please specify a channel'
  exit 1
fi

if [[ ! $WERCKER_SLACK_NOTIFY_CHANNEL == \#* ]]; then
error "Please specify the channel without the '#'"
  exit 1
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_FAILED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: build of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY failed."
  else
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: deploy to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY failed."
  fi
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_PASSED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: build of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY passed."
  else
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: deploy to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY passed."
  fi
fi

if [ "$WERCKER_RESULT" = "passed" ]; then
  export WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_PASSED_MESSAGE"
else
  export WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_FAILED_MESSAGE"
fi


if [ "$WERCKER_SLACK_NOTIFY_ON" = "failed" ]; then
  if [ "$WERCKER_RESULT" = "passed" ]; then
    echo "Skipping.."
    return 0
  fi
fi

json="{\"channel\": \"#$WERCKER_SLACK_NOTIFY_CHANNEL\", \"text\": \"$WERCKER_SLACK_NOTIFY_MESSAGE\"}"

curl -s -d "payload=$json" "https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/services/hooks/incoming-webhook?token=$WERCKER_SLACK_NOTIFY_TOKEN"
