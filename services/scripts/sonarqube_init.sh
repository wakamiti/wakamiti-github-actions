#!/bin/bash

apt-get install -y jq
/opt/sonarqube/docker/entrypoint.sh &
while ! curl -sSf http://localhost:9000/api/system/status | grep -q -e '"status":"UP"' > /dev/null; do sleep 5; done
params="login=admin&previousPassword=admin&password=$ADMIN_PASSWORD"
curl -u admin:admin -X POST "http://localhost:9000/api/users/change_password?$params"
curl -u admin:$ADMIN_PASSWORD -X POST "http://localhost:9000/api/projects/create" \
  -d "project=wakamiti-github-actions&name=Test"
curl -u admin:$ADMIN_PASSWORD -X POST "http://sonarqube:9000/api/user_tokens/generate?name=my-token" | grep \
  -oP '"token":\s*"\K[^"]+' > /out/token
wait
