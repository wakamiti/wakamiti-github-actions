#!/bin/bash

./nexus/bin/nexus run &
while ! curl -sSf http://localhost:8081/service/rest/v1/status > /dev/null; do sleep 10; done
curl -u admin:admin123 -X POST 'http://localhost:8081/service/rest/v1/repositories/maven/hosted' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "maven-internal",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "allow_once"
    },
    "cleanup": {
      "policyNames": [
        "string"
      ]
    },
    "component": {
      "proprietaryComponents": true
    },
    "maven": {
      "versionPolicy": "MIXED",
      "layoutPolicy": "PERMISSIVE",
      "contentDisposition": "ATTACHMENT"
    }
  }'
curl -u admin:admin123 -X POST 'http://localhost:8081/service/rest/v1/repositories/maven/hosted' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "maven-snapshots",
    "snapshot": true,
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "allow_once"
    },
    "cleanup": {
      "policyNames": [
        "string"
      ]
    },
    "component": {
      "proprietaryComponents": true
    },
    "maven": {
      "versionPolicy": "MIXED",
      "layoutPolicy": "STRICT",
      "contentDisposition": "ATTACHMENT"
    }
  }'
wait


