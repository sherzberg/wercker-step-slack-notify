#!/bin/bash

USERNAME="\"username\":\"Wercker\","
AVATAR="\"icon_url\":\"https://avatars3.githubusercontent.com/u/1695193?s=140\","

if [ ! -n "$WERCKER_SLACK_NOTIFY_SUBDOMAIN" ]; then
# fatal causes the wercker interface to display the error without the need to
# expand the step
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

if [ -n "$WERCKER_SLACK_NOTIFY_USERNAME" ]; then
  USERNAME="\"username\":\"$WERCKER_SLACK_NOTIFY_USERNAME\","
fi

if [ -n "$WERCKER_SLACK_NOTIFY_ICON_EMOJI" ]; then
  AVATAR="\"icon_emoji\":\"$WERCKER_SLACK_NOTIFY_ICON_EMOJI\","
fi
if [ -n "$WERCKER_SLACK_NOTIFY_ICON_URL" ]; then
  AVATAR="\"icon_url\":\"$WERCKER_SLACK_NOTIFY_ICON_URL\","
fi



if [ ! -n "$WERCKER_SLACK_NOTIFY_FAILED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_BUILD_URL|build> of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY failed."
  else
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_DEPLOY_URL|deploy> of $WERCKER_GIT_BRANCH to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY failed."
  fi
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_PASSED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_BUILD_URL|build> of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY passed."
  else
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_DEPLOY_URL|deploy of $WERCKER_GIT_BRANCH> to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY passed."
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

json="{\"channel\": \"$WERCKER_SLACK_NOTIFY_CHANNEL\", $USERNAME $AVATAR \"text\": \"$WERCKER_SLACK_NOTIFY_MESSAGE\"}"

RESULT=`curl -s -d "payload=$json" "https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/services/hooks/incoming-webhook?token=$WERCKER_SLACK_NOTIFY_TOKEN" --output $WERCKER_STEP_TEMP/result.txt -w "%{http_code}"`

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" $WERCKER_STEP_TEMP/result.txt; then
    fatal "No token is specified."
  fi

  if grep -Fqx "No hooks" $WERCKER_STEP_TEMP/result.txt; then
    fatal "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" $WERCKER_STEP_TEMP/result.txt; then
    fatal "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" $WERCKER_STEP_TEMP/result.txt; then
    fatal "No text specified."
  fi

  # Unhandled error
  # fatal <$WERCKER_STEP_TEMP/result.txt
fi

if [ "$RESULT" = "404" ]; then
  error "Subdomain or token not found."
  exit 1
fi
