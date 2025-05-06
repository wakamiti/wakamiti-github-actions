#!/bin/bash

./entrypoint-artifactory.sh &
while ! curl -sSf http://localhost:8081/artifactory/api/system/ping > /dev/null 2>&1; do sleep 5; done
curl -u tester:password -X POST 'http://localhost:8081/artifactory/api/repositories/maven-snapshots' \
    -H 'Content-Type: application/json' \
    -d '{"key":"maven-snapshots","rclass":"local","packageType":"maven","snapshotVersionBehavior":"unique"}'
wait