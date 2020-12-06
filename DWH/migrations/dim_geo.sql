USE data_mars_sales;

DROP TABLE IF EXISTS dim_geo;
CREATE TABLE dim_geo(
    id INTEGER PRIMARY KEY,
    country_name VARCHAR(50),
    country_id INTEGER,
    state_name VARCHAR(50),
    state_id INTEGER,
    municipality_name VARCHAR(50),
    municipality_id INTEGER,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE './dim_geo.csv'
INTO TABLE dim_geo
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
