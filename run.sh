#!/bin/bash

AVATAR=''
USERNAME=''

if [ -n "$DEPLOY" ]; then
  if [ -n "$ROBBIE_URL" ]; then
    if [ -n "$ENVIRONMENT" ]; then
      # Check if this environment is enabled; if not, exit gracefully
      if [ "$(curl $ROBBIE_URL/$ENVIRONMENT 2>/dev/null)" != "on" ]; then
        echo "$ENVIRONMENT disabled; not sending notification"
        exit 0
      fi
    fi
  fi
fi

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

if [[ $WERCKER_SLACK_NOTIFY_CHANNEL == \#* ]]; then
  error "Please specify the channel without the '#'"
fi

pushd $WERCKER_SOURCE_DIR
WERCKER_GIT_COMMIT_MESSAGE=$(git log -1 --pretty='%s' 2>&1)
if [ ${WERCKER_GIT_COMMIT_MESSAGE:0:6} == "fatal:" ] ; then
  WERCKER_GIT_COMMIT_MESSAGE="(null)"
fi
popd

WERCKER_STATUS_URL=$WERCKER_BUILD_URL
if [ -n "$DEPLOY" ]; then
    WERCKER_STATUS_URL=$WERCKER_DEPLOY_URL
fi

BUILD_OR_DEPLOY="Build"
if [ -n "$DEPLOY" ]; then
  BUILD_OR_DEPLOY="Deploy ($WERCKER_DEPLOYTARGET_NAME)"
fi

BUILD_COLOR=\"danger\"
BUILD_STATUS_ATTACHMENT="{ \"title\": \"$BUILD_OR_DEPLOY failed\", \"value\": \"<$WERCKER_STATUS_URL|$WERCKER_GIT_COMMIT_MESSAGE>\", \"short\": true }"
if [ "$WERCKER_RESULT" == "passed" ]; then
  BUILD_COLOR=\"good\"
  BUILD_STATUS_ATTACHMENT="{ \"title\": \"$BUILD_OR_DEPLOY succeeded\", \"value\": \"<$WERCKER_STATUS_URL|$WERCKER_GIT_COMMIT_MESSAGE>\", \"short\": true }"
fi

BUILD_COMMITTER_ATTACHMENT="{ \"title\": \"Committer\", \"value\": \"$WERCKER_STARTED_BY\", \"short\": true }"
BUILD_BRANCH_ATTACHMENT="{ \"title\": \"Branch\", \"value\": \"$WERCKER_GIT_BRANCH\", \"short\": true }"
BUILD_PROJECT_ATTACHMENT="{ \"title\": \"Project\", \"value\": \"$WERCKER_APPLICATION_NAME\", \"short\": true }"

if [ "$WERCKER_SLACK_NOTIFY_ON" == "failed" ]; then
  if [ "$WERCKER_RESULT" == "passed" ]; then
    echo "Skipping.."
    return 0
  fi
fi

ATTACHMENTS="\"attachments\": [ { \"fallback\": \"build status\", \"color\": $BUILD_COLOR, \"fields\": [ $BUILD_STATUS_ATTACHMENT, $BUILD_COMMITTER_ATTACHMENT, $BUILD_BRANCH_ATTACHMENT, $BUILD_PROJECT_ATTACHMENT ] } ]"

json="{\"channel\": \"#$WERCKER_SLACK_NOTIFY_CHANNEL\", $USERNAME $AVATAR \"text\": \"$WERCKER_SLACK_NOTIFY_MESSAGE\", $ATTACHMENTS }"

RESULT=$(curl -s -d "payload=$json" "https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/services/hooks/incoming-webhook?token=$WERCKER_SLACK_NOTIFY_TOKEN" --output $WERCKER_STEP_TEMP/result.txt -w "%{http_code}")

echo "PAYLOAD: " $json
echo "RESULT: " $(cat $WERCKER_STEP_TEMP/result.txt)

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
