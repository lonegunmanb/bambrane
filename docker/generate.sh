#!/bin/ash
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"
CONTENT_LENGTH_HEADER="Content-Length: 0"
if [ "$RUNNER_SCOPE" == "repo" ]; then
  curl \
    -fsSL \
    -H "${CONTENT_LENGTH_HEADER}" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X POST \
    https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/registration-token | jq -r .token > /token/token
elif [ "$RUNNER_SCOPE" == "org" ]; then
  curl \
    -fsSL \
    -H "${CONTENT_LENGTH_HEADER}" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X POST \
    https://api.github.com/orgs/${ORG}/actions/runners/registration-token | jq -r .token > /token/token
fi

until [[ ! -f /token/token ]]
do
     sleep 1
done