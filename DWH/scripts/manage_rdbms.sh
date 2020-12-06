#!/bin/sh

CONTAINER="rdbms_staging"
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD

mysql $MYSQL_DATABASE -u root
