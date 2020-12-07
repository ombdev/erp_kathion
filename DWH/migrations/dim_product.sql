
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    id             INTEGER NOT NULL PRIMARY KEY,   -- Surrogate key
    sku            VARCHAR(9) NOT NULL,            -- Business key
    description    VARCHAR(100) NOT NULL
) Engine=InnoDB;
