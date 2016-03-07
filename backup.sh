#!/usr/bin/env bash

# Script to backup all databases and mysql data.
# Should either watch a backup mutex file to know when to backup.
# Should use configured credentials and exit when complete.

SECRETS_PATH=${SECRETS_PATH:-/etc/galera-secrets}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(cat ${SECRETS_PATH}/mysql-root-password)}

