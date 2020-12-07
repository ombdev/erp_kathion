
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    id        INTEGER PRIMARY KEY,    -- Surrogate key
    control   VARCHAR(25) NOT NULL,   -- Business key
    name      VARCHAR(100) NOT NULL
) Engine=InnoDB;
