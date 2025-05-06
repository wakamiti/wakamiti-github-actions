#!/bin/bash

./nexus/bin/nexus run &
while ! curl -sSf http://localhost:8081/service/rest/v1/status > /dev/null; do sleep 10; done

# Cambiar el nombre de usuario del administrador a 'tester'
curl -u admin:xK9#mP2@ -X PUT 'http://localhost:8081/service/rest/v1/security/users/admin' \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "tester",
    "firstName": "Tester",
    "lastName": "User",
    "emailAddress": "tester@example.com",
    "password": "xK9#mP2@",
    "status": "active",
    "roles": ["nx-admin"]
  }'

# Crear repositorios
curl -u tester:xK9#mP2@ -X POST 'http://localhost:8081/service/rest/v1/repositories/maven/hosted' \
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
curl -u tester:xK9#mP2@ -X POST 'http://localhost:8081/service/rest/v1/repositories/maven/hosted' \
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


