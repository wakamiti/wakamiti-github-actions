#!/bin/bash

./entrypoint-artifactory.sh &
while ! curl -sSf http://localhost:8081/artifactory/api/system/ping > /dev/null; do sleep 5; done
curl -u admin:password -X POST 'http://localhost:8081/artifactory/api/repositories/maven-snapshots' \
    -H 'Content-Type: application/json' \
    -d '{"key":"maven-snapshots","rclass":"local","packageType":"maven","snapshotVersionBehavior":"unique"}'
wait

curl -u admin:password -X POST 'http://localhost:8081/artifactory/api/repositories/maven-snapshots' -H 'Content-Type: application/json' -d '{"key":"maven-snapshots","rclass":"local","packageType":"maven","snapshotVersionBehavior":"unique"}'
