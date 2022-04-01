#!/usr/bin/env bash
az login --identity || true
az group delete --name $RESOURCE_GROUP_NAME -y || true
export RUNNER_TOKEN=$(cat /token/token)
/entrypoint.sh ./bin/Runner.Listener run --startuptype service