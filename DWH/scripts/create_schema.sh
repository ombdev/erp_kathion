#!/bin/sh -e


CONTAINER="rdbms_staging"
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD

echo "Creating database..."
echo "DROP DATABASE IF EXISTS $MYSQL_DATABASE; CREATE DATABASE $MYSQL_DATABASE;" | mysql -u root

cd /migrations

echo "Creating dimension time"
# Creates the time dimension along with its data
mysql $MYSQL_DATABASE -u root < dim_time.sql

echo "Creating geographic time"
# Creates the geopraphic along with its data
mysql $MYSQL_DATABASE -u root < dim_geo.sql
