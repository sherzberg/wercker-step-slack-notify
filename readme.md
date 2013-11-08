[![wercker status](https://app.wercker.com/status/6077bdbf04300a6412268672fa39e71b/m "wercker status")](https://app.wercker.com/project/bykey/6077bdbf04300a6412268672fa39e71b)

# slack-notify

Send a message to a Slack Channel

### required

* `token` - Your Slack token.
* `channel` - The channel name of the Slack Channel
* `subdomain` - The Campfire subdomain.


Example
--------

Add SLACK_TOKEN as deploy target or application environment variable.


    build:
        after-steps:
            - slack-notify:
                subdomain: slacksubdomain
                token: $SLACK_TOKEN
                channel: general
