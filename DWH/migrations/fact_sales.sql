DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales(
    id INTEGER PRIMARY KEY,
    dim_customer_id INTEGER,
    dim_time_id INTEGER,
    dim_geo_id INTEGER,
    dim_product_id INTEGER,
    qty_sold DECIMAL(6,4),
    amt_sold DECIMAL(10,4),
    CONSTRAINT fk_dim_customer FOREIGN KEY (dim_customer_id) REFERENCES dim_customer(id),
    CONSTRAINT fk_dim_geo FOREIGN KEY (dim_geo_id) REFERENCES dim_geo(id),
    CONSTRAINT fk_dim_product FOREIGN KEY (dim_product_id) REFERENCES dim_product(id)
) ENGINE=InnoDB;
