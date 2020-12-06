#!/bin/sh -e

echo "Creating database..."

CONTAINER="rdbms_staging"
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD


echo "CREATE DATABASE $MYSQL_DATABASE;" | mysql -u root -h 127.0.0.1

# Creates the time dimension along with its data
mysql $MYSQL_DATABASE -u root < /migrations/dim_time.sql

# Creates the geopraphic along with its data
mysql $MYSQL_DATABASE -u root < /migrations/dim_geo.sql
