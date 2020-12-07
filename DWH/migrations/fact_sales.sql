DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales(
    id INTEGER NOT NULL PRIMARY KEY,
    dim_customer_id INTEGER NOT NULL,
    dim_time_id INTEGER NOT NULL,
    dim_geo_id INTEGER NOT NULL,
    dim_product_id INTEGER NOT NULL,
    qty_sold DECIMAL(6,4) NOT NULL,
    amt_sold DECIMAL(10,4) NOT NULL,
    CONSTRAINT fk_dim_customer FOREIGN KEY (dim_customer_id) REFERENCES dim_customer(id),
    CONSTRAINT fk_dim_geo FOREIGN KEY (dim_geo_id) REFERENCES dim_geo(id),
    CONSTRAINT fk_dim_product FOREIGN KEY (dim_product_id) REFERENCES dim_product(id),
    CONSTRAINT fk_dim_time FOREIGN KEY (dim_time_id) REFERENCES dim_time(id)
) ENGINE=InnoDB;
