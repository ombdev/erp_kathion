#!/bin/sh -e

echo "Creating database..."

CONTAINER="rdbms_staging"

mysql -p $MYSQL_DATABASE -u root < /migrations/setup_schema.sql

# Creates the time dimension along with its data
mysql -p $MYSQL_DATABASE -u root < /migrations/dim_time.sql

# Creates the geopraphic along with its data
mysql -p $MYSQL_DATABASE -u root < /migrations/dim_geo.sql
