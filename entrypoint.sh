#!/bin/bash
set -e

TOKEN=$INPUT_GITHUB_TOKEN
REPO=$INPUT_REPO_NAME
PULL_NUMBER=$INPUT_PR_NUMBER
ORG_PR_REVIEWERS=$INPUT_PR_REVIEWERS
DO_COMMENT=$INPUT_DO_COMMENT
CUSTOM_COMMENT=$INPUT_CUSTOM_COMMENT

if [[ -z $TOKEN ]]; then
  echo "Error: Missing input 'github_token'"
  exit 1
elif [[ -z $REPO ]]; then
  echo "Error: Missing input 'repo_name'"
  exit 1
elif [[ -z $PULL_NUMBER ]]; then
  echo "Error: Missing input 'pr_number'"
  exit 1
elif [[ -z $ORG_PR_REVIEWERS ]]; then
  echo "Error: Missing input 'pr_reviewers'"
  exit 1
elif [[ -z $DO_COMMENT ]]; then
  echo "Error: Missing input 'do_comment'"
  exit 1
fi

IFS=',' read -r -a array <<< $ORG_PR_REVIEWERS
for index in "${!array[@]}"
do
  array[index]=`echo ${array[index]} | xargs`
  array[index]="\"${array[index]}\""
done
PR_REVIEWERS=$(IFS=','; echo "${array[*]}")

# CURL to add reviewers using PR_REVIEWERS
_RESPONSE=$(curl --silent -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"reviewers\": [${PR_REVIEWERS}]}" \
  "https://api.github.com/repos/${REPO}/pulls/${PULL_NUMBER}/requested_reviewers")

reviewers=$(echo "${_RESPONSE}" | jq -r '.requested_reviewers')

if [ "${reviewers}" != "null" ]; then
  reviewers=$(echo "${_RESPONSE}" | jq -r '.requested_reviewers | .[] | .login')
  echo "Reviewers have been added successfully"
else
  echo "Failed to add reviewers. Error: $(echo ${_RESPONSE} | jq  -r '.message')"
  exit 1
fi

if [ "$DO_COMMENT" != "true" ]; then
  echo "Comment is disabled"
  exit 0
fi

# Add comment to the PR to notify the reviewers
IFS=',' read -r -a array <<< $ORG_PR_REVIEWERS
for index in "${!array[@]}"
do
  array[index]="@${array[index]}"
done
PR_REVIEWERS=$(IFS=','; echo "${array[*]}")

COMMENT="Review require ${PR_REVIEWERS}"

if [ ! -z "$CUSTOM_COMMENT" ]; then
  COMMENT=$CUSTOM_COMMENT
fi

_RESPONSE=`curl --silent -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"body\": \"${COMMENT}\"}" \
  "https://api.github.com/repos/${REPO}/issues/${PULL_NUMBER}/comments"`
id=$(echo "${_RESPONSE}" | jq -r '.id')

if [ "${id}" != "null" ]; then
  echo "Comment has been created successfully"
else
  echo "Failed to create comment. Error: $(echo ${_RESPONSE} | jq  -r '.message')"
  exit 1
fi