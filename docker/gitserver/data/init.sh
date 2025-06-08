#!/bin/bash

GITEA="/usr/local/bin/gitea"
APP_INI="/data/gitea/conf/app.ini"

/usr/bin/entrypoint &
apk --no-cache add jq
while ! curl -sSf http://localhost:3000/api/healthz > /dev/null 2>&1; do sleep 5; done
$(dirname "$0")/create_user.sh $USERNAME $PASSWORD
response=$(curl -u $USERNAME:$PASSWORD -X POST "http://localhost:3000/api/v1/users/${USERNAME}/tokens" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
     {
       "name": "test_token",
       "scopes":[
         "read:activitypub",
         "read:issue",
         "write:misc",
         "read:notification",
         "read:organization",
         "write:package",
         "write:repository",
         "read:user"
       ]
     }
EOF
)
echo $response | jq -r '.sha1' > /workspace/token.txt
wait