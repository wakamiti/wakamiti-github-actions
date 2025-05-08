#!/bin/bash

TOKEN=$(cat /root/token)

PROJECT_IDS=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" 'http://localhost/api/v4/projects?per_page=100' | \
  jq '.[].id')

# Iterar sobre cada ID y eliminar el proyecto
for id in $PROJECT_IDS; do
  echo Deleting repo $id...
  curl -s -o /dev/null -X DELETE "http://localhost/api/v4/projects/$id" --header "PRIVATE-TOKEN: $TOKEN"
done