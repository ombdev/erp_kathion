DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales(
    id INTEGER PRIMARY KEY,
    dim_customer_id INTEGER,
    dim_time_id INTEGER,
    dim_geo_id INTEGER,
    dim_product_id INTEGER
) ENGINE=InnoDB;
