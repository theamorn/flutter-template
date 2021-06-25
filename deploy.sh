#!/bin/bash
# Read and change Build number in Pubspec
set -e
cd ios
fastlane buildNumber
cd ..

# Start Building App
flutter clean
flutter build apk --flavor dev --release -t lib/main_sit.dart --target-platform android-arm,android-arm64
cd android
fastlane beta &
cd ..
flutter build ios --flavor dev --release -t lib/main_sit.dart --no-codesign
cd ios
fastlane beta
cd ..

# Read pubspec.yaml to get version
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml pubspec.yaml)
pubspecVersion=$version
# Replace + with -
versionNumber=${pubspecVersion/+/-}

# Post to Slack
curl -X POST -H 'Content-type: application/json' \
--data '{"text":"Hey <!here>, iOS/Android version '$versionNumber' are released"}' \
https://hooks.slack.com/services/xxxxxx

# Post to line
curl -v -X POST https://api.line.me/v2/bot/message/push \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer xxxxxx' \
-d '{
    "to": "xxxxx",
    "messages":[
        {
            "type":"text",
            "text":"Hey all, iOS/Android version '$versionNumber' are released"
        }
    ]
}'

# GitLab/Github Access Token
access_token="xxxxx"
gitID=xxxxx
jiraID=xxxxx
jiraToken=xxxxx

# Add Git tags
curl --silent --request POST \
--header "PRIVATE-TOKEN: $access_token" \
"https://gitlab.com/api/v4/projects/$gitID/repository/tags?tag_name=$versionNumber&ref=master"

# Add Jira version
curl --silent POST --url 'https://xxxxx.atlassian.net/rest/api/3/version' \
--header 'Authorization: Basic '$jiraToken'' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--data '{"archived": false, "name": "'"$versionNumber"'", "projectId": "'$jiraID'", "released": false}'
#
# Get Transition
# 16156 is Issue ID, you can get from any id from that Board by calling jql Project below
# curl --request GET \
#   --url 'https://xxxxx.atlassian.net/rest/api/3/issue/16156/transitions' \
#   --header 'Authorization: Basic '$jiraToken'' \
#   --header 'Accept: application/json'

# Get All user, just in case you want to assign to specific permission_handler
# curl --request GET \
#   --url 'https://xxxxx.atlassian.net/rest/api/3/users/search?maxResults=100' \
#   --header 'Authorization: Basic '$jiraToken'' \
#   --header 'Accept: application/json' | jq -r '.[] | (.accountId + " : " + .displayName)'

# Search in jql only specific project
# replace YYYY with your JQL
# sample's here, my team iss NEO, and Look for Status REVIEWED and FIXED
# NEO AND status IN (\"REVIEWED\", \"FIXED\") ORDER BY created DESC
for idParams in $(curl --request POST --url 'https://xxxxx.atlassian.net/rest/api/3/search' \
  --header 'Authorization: Basic '$jiraToken'' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data '{
  "expand": [
    "names"
  ],
  "jql": "project = ",
  "maxResults": 1000,
  "fieldsByKeys": false,
  "fields": [
    "creator",
    "id"
  ],
  "startAt": 0
}' | jq -r '.issues[] | (.fields.creator.accountId + "," + .id)'); do
    params=(${idParams//,/ })
    accountID=${params[0]}
    issueID=${params[1]}

    # Assign
    curl --request PUT \
      --url "https://xxxx.atlassian.net/rest/api/3/issue/$issueID/assignee" \
      --header 'Authorization: Basic '$jiraToken'' \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{
      "accountId": "'$accountID'"
      }'

    # Update Fixed version from Tag
    curl --request PUT \
      --url "https://xxxx.atlassian.net/rest/api/3/issue/$issueID" \
      --header 'Authorization: Basic '$jiraToken'' \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{
        "fields": {
          "fixVersions": [{
            "name": "'$versionNumber'"
          }]
        }
      }'

    # Move Ticket to Position
    # ID 71 is just a sample, You can change by using # Get Transition Section
    curl --request POST \
      --url "https://xxxxx.atlassian.net/rest/api/3/issue/$issueID/transitions" \
      --header 'Authorization: Basic '$jiraToken'' \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{
        "transition": {
          "id": "71"
        }
      }'
done
