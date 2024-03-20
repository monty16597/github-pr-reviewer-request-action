#!/bin/bash
set -e

TOKEN=$INPUT_GITHUB_TOKEN
OWNER=$INPUT_REPO_OWNER
REPO=$INPUT_REPO_NAME
PULL_NUMBER=$INPUT_PR_NUMBER
ORG_MAINTAINER_USERNAMES=$INPUT_PR_REVIEWERS

if [[ -z $TOKEN ]]; then
  echo "Error: Missing input 'github_token'"
  exit 1
elif [[ -z $OWNER ]]; then
  echo "Error: Missing input 'repo_owner'"
  exit 1
elif [[ -z $REPO ]]; then
  echo "Error: Missing input 'repo_name'"
  exit 1
elif [[ -z $PULL_NUMBER ]]; then
  echo "Error: Missing input 'pr_number'"
  exit 1
elif [[ -z $ORG_MAINTAINER_USERNAMES ]]; then
  echo "Error: Missing input 'pr_reviewers'"
  exit 1
fi

IFS=',' read -r -a array <<< $ORG_MAINTAINER_USERNAMES
for index in "${!array[@]}"
do
  array[index]=`echo ${array[index]} | xargs`
  array[index]="\"${array[index]}\""
done
MAINTAINER_USERNAMES=$(IFS=','; echo "${array[*]}")

# CURL to add reviewers using MAINTAINER_USERNAMES
_RESPONSE=$(curl --silent -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"reviewers\": [${MAINTAINER_USERNAMES}]}" \
  "https://api.github.com/repos/${OWNER}/${REPO}/pulls/${PULL_NUMBER}/requested_reviewers")

reviewers=$(echo "${_RESPONSE}" | jq -r '.requested_reviewers')

if [ "${reviewers}" != "null" ]; then
  reviewers=$(echo "${_RESPONSE}" | jq -r '.requested_reviewers | .[] | .login')
  echo "Reviewers have been added successfully"
else
  echo "Failed to add reviewers. Error: $(echo ${_RESPONSE} | jq  -r '.message')"
  exit 1
fi


# Add comment to the PR to notify the reviewers
IFS=',' read -r -a array <<< $ORG_MAINTAINER_USERNAMES
for index in "${!array[@]}"
do
  array[index]="@${array[index]}"
done
MAINTAINER_USERNAMES=$(IFS=','; echo "${array[*]}")

_RESPONSE=`curl --silent -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"body\": \"Review require ${MAINTAINER_USERNAMES}\"}" \
  "https://api.github.com/repos/${OWNER}/${REPO}/issues/${PULL_NUMBER}/comments"`
id=$(echo "${_RESPONSE}" | jq -r '.id')

if [ "${id}" != "null" ]; then
  echo "Comment has been created successfully"
else
  echo "Failed to create comment. Error: $(echo ${_RESPONSE} | jq  -r '.message')"
  exit 1
fi