
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    id        INTEGER PRIMARY KEY,
    control   VARCHAR(25) NOT NULL,
    name      VARCHAR(100) NOT NULL
) Engine=InnoDB;
