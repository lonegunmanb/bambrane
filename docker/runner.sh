#!/usr/bin/env bash
until [ -f /token/token ]
do
     sleep 1
done

az login --identity || true
az group delete --name $RESOURCE_GROUP_NAME -y || true
az group create --name $RESOURCE_GROUP_NAME --location $TF_VAR_location
export RUNNER_TOKEN=$(cat /token/token)
/entrypoint.sh ./bin/Runner.Listener run --startuptype service
echo "==>Deleting token"
rm /token/token