#!/bin/sh

GITEA="/usr/local/bin/gitea"
APP_INI="/data/gitea/conf/app.ini"
REPOS_DIR=/data/git/repositories

# List repos
repos=$(find ${REPOS_DIR}/${USERNAME} -type d -name '*.git' | sed "s|.*/${USERNAME}/||" | sed 's|.git$||')
for repo in $repos; do
  echo "Deleting repo: ${USERNAME}/${repo}..."
  curl -u $USERNAME:$PASSWORD -X DELETE "${GITEA__server__ROOT_URL}/api/v1/repos/${USERNAME}/${repo}"
done
