#!/bin/bash

GITEA="/usr/local/bin/gitea"
APP_INI="/data/gitea/conf/app.ini"


su - git -c \
    "$GITEA admin user list --config $APP_INI | grep -qw "$1" || $GITEA admin user create --username $1 --password $2 --email ${1}@example.com --config $APP_INI --must-change-password=false"
