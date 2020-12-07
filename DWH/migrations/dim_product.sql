
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    id             INTEGER PRIMARY KEY,
    sku            VARCHAR(9) NOT NULL,
    description    VARCHAR(100) NOT NULL
) Engine=InnoDB;
