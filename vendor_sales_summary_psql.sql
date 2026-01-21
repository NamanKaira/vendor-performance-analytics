-- Drop old tables if they exist (run first)
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS purchase_prices;
DROP TABLE IF EXISTS vendor_invoice;
DROP TABLE IF EXISTS sales;

-- PURCHASES TABLE
-- Contains actual purchase data, including the date of purchase, products (brands) 
-- purchased by vendors, the amount paid (in dollars), and the quantity purchased
CREATE TABLE purchases (
    inventory_id    TEXT,
    store           INT,
    brand           INT,
    description     TEXT,
    size            TEXT,
    vendor_number   INT,
    vendor_name     TEXT,
    po_number       INT,            -- can be TEXT if you want to keep leading zeros
    po_date         DATE,
    receiving_date  DATE,
    invoice_date    DATE,
    pay_date        DATE,
    purchase_price  NUMERIC(10,2),
    quantity        INT,
    dollars         NUMERIC(12,2),
    classification  INT
);

-- PURCHASE_PRICES TABLE
-- Provides product-wise actual and purchase prices
-- The combination of vendor and brand is unique in this table
CREATE TABLE purchase_prices (
    brand           INT,
    description     TEXT,
    price           NUMERIC(10,2),
    size            TEXT,
    volume          TEXT,
    classification  INT,
    purchase_price  NUMERIC(10,2),
    vendor_number   INT,
    vendor_name     TEXT
);

-- VENDOR_INVOICE TABLE
-- Aggregates data from the purchases table, summarizing quantity and dollar amounts,
-- along with an additional column for freight
-- This table maintains uniqueness based on vendor and PO number
CREATE TABLE vendor_invoice (
    vendor_number   INT,
    vendor_name     TEXT,
    invoice_date    DATE,
    po_number       INT,            -- use TEXT if PO numbers can be non‑numeric
    po_date         DATE,
    pay_date        DATE,
    quantity        INT,
    dollars         NUMERIC(12,2),
    freight         NUMERIC(12,2),
    approval        TEXT
);

-- SALES TABLE
-- Captures actual sales transactions, detailing the brands purchased by vendors,
-- the quantity sold, the selling price, and the revenue earned
CREATE TABLE sales (
    inventory_id    TEXT,
    store           INT,
    brand           INT,
    description     TEXT,
    size            TEXT,
    sales_quantity  INT,
    sales_dollars   NUMERIC(12,2),
    sales_price     NUMERIC(10,2),
    sales_date      DATE,
    volume          NUMERIC(10,2),
    classification  INT,
    excise_tax      NUMERIC(10,2),
    vendor_no       INT,
    vendor_name     TEXT
);

-- ============================================================================
-- STEP 3: LOAD CSV FILES INTO TABLES
-- ============================================================================
-- Load data from CSV files into the staging tables
-- Note: Update the file paths according to your actual CSV file locations
-- Note: Ensure the CSV files have headers matching the column names

-- Load purchases data
COPY purchases 
FROM 'C:/Program Files/PostgreSQL/18/data/purchases.csv'
WITH (FORMAT CSV, HEADER true);


-- Load purchase_prices data
COPY purchase_prices
FROM 'C:/Program Files/PostgreSQL/18/data/purchase_prices.csv'
WITH (
    FORMAT csv,
    HEADER true,
    NULL 'Unknown'
);

-- Load vendor_invoice data
COPY vendor_invoice
FROM 'C:/Program Files/PostgreSQL/18/data/vendor_invoice.csv'
WITH (FORMAT CSV, HEADER true);

-- Load sales data
COPY sales
FROM 'C:/Program Files/PostgreSQL/18/data/sales.csv'
WITH (FORMAT CSV, HEADER true);

-- ============================================================================
-- EXPLORATORY DATA ANALYSIS - CHECK TABLES
-- ============================================================================
-- Checking tables present in the database
-- This query lists all tables in the current schema
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================================
-- EXPLORATORY DATA ANALYSIS - TABLE RECORD COUNTS
-- ============================================================================
-- Exploring what type of data is available in the tables
-- Getting count of records for each table

-- Count records in purchases table
SELECT 'purchases' AS table_name, COUNT(*) AS record_count FROM purchases;

-- Count records in purchase_prices table
SELECT 'purchase_prices' AS table_name, COUNT(*) AS record_count FROM purchase_prices;

-- Count records in vendor_invoice table
SELECT 'vendor_invoice' AS table_name, COUNT(*) AS record_count FROM vendor_invoice;

-- Count records in sales table
SELECT 'sales' AS table_name, COUNT(*) AS record_count FROM sales;

-- ============================================================================
--  EXPLORATORY DATA ANALYSIS - SAMPLE DATA
-- ============================================================================
-- Viewing sample data from each table (first 5 rows)
-- This helps understand the structure and content of each table

-- Sample data from purchases table
SELECT * FROM purchases LIMIT 5;

-- Sample data from purchase_prices table
SELECT * FROM purchase_prices LIMIT 5;

-- Sample data from vendor_invoice table
SELECT * FROM vendor_invoice LIMIT 5;

-- Sample data from sales table
SELECT * FROM sales LIMIT 5;


-- ============================================================================
--  EXPLORATORY DATA ANALYSIS - SINGLE VENDOR EXPLORATION
-- ============================================================================
-- Choosing one vendor (VendorNumber = 4466) and filtering the different tables
-- This helps understand how vendor-related data is distributed across tables

-- Purchases for vendor 4466
SELECT * 
FROM purchases 
WHERE vendor_number = 4466
LIMIT 10;

-- Purchase prices for vendor 4466
SELECT * 
FROM purchase_prices 
WHERE vendor_number = 4466
LIMIT 10;

-- Vendor invoices for vendor 4466
SELECT * 
FROM vendor_invoice 
WHERE vendor_number = 4466
LIMIT 10;

-- Sales for vendor 4466
SELECT * 
FROM sales 
WHERE vendor_no = 4466
LIMIT 10;

-- ============================================================================
--  EXPLORATORY DATA ANALYSIS - GROUPBY SUMMARIES
-- ============================================================================
-- Understanding data aggregations for a single vendor

-- Purchases grouped by Brand and PurchasePrice
-- This shows quantity and dollars spent per brand and purchase price combination
SELECT 
    brand,
    purchase_price,
    SUM(quantity) AS total_quantity,
    SUM(dollars) AS total_dollars
FROM purchases 
WHERE vendor_number = 4466
GROUP BY brand, purchase_price
ORDER BY total_dollars DESC;

-- Purchases grouped by PO Number
-- This shows quantity and dollars spent per purchase order
SELECT 
    po_number,
    SUM(quantity) AS total_quantity,
    SUM(dollars) AS total_dollars
FROM purchases 
WHERE vendor_number = 4466
GROUP BY po_number
ORDER BY total_dollars DESC;

-- Sales grouped by Brand
-- This shows sales metrics per brand
SELECT 
    brand,
    SUM(sales_quantity) AS total_sales_quantity,
    SUM(sales_dollars) AS total_sales_dollars,
    SUM(sales_price) AS total_sales_price,
    SUM(excise_tax) AS total_excise_tax
FROM sales 
WHERE vendor_no = 4466
GROUP BY brand
ORDER BY total_sales_dollars DESC;


-- ============================================================================
--  CREATE SUMMARY VIEWS
-- ============================================================================
-- As the data needed for analysis is distributed in different tables,
-- we need to create summary views containing:
-- - purchase transactions made by vendors
-- - sales transaction data
-- - freight costs for each vendor
-- - actual product prices from vendors

-- Let's first explore each summary in different views

-- FREIGHT SUMMARY VIEW
-- Aggregates freight costs by vendor
CREATE OR REPLACE VIEW freight_summary AS
SELECT 
    vendor_number, 
    SUM(freight) AS freight_cost 
FROM vendor_invoice 
GROUP BY vendor_number;

-- View the freight summary
SELECT * FROM freight_summary ORDER BY freight_cost DESC LIMIT 10;


-- PURCHASE SUMMARY VIEW
-- Joins purchases with purchase_prices to get actual prices and volumes
-- Groups by vendor, brand, and other key attributes
-- Filters out records with zero purchase price
CREATE OR REPLACE VIEW purchase_summary AS
SELECT 
    p.vendor_number,
    p.vendor_name,
    p.brand,
    p.description,
    p.purchase_price,
    pp.price AS actual_price,
    pp.volume,
    SUM(p.quantity) AS total_purchase_quantity,
    SUM(p.dollars) AS total_purchase_dollars
FROM purchases p
JOIN purchase_prices pp ON p.brand = pp.brand
WHERE p.purchase_price > 0
GROUP BY 
    p.vendor_number,
    p.vendor_name, 
    p.brand, 
    p.description, 
    p.purchase_price, 
    pp.price, 
    pp.volume
ORDER BY total_purchase_dollars DESC;

-- View the purchase summary
SELECT * FROM purchase_summary LIMIT 10;

-- SALES SUMMARY VIEW
-- Aggregates sales data by vendor and brand
CREATE OR REPLACE VIEW sales_summary AS
SELECT 
    vendor_no,
    brand,
    SUM(sales_quantity) AS total_sales_quantity,
    SUM(sales_dollars) AS total_sales_dollars,
    SUM(sales_price) AS total_sales_price,
    SUM(excise_tax) AS total_excise_tax
FROM sales
GROUP BY vendor_no, brand;

-- View the sales summary
SELECT * FROM sales_summary LIMIT 10;

-- ============================================================================
--  CREATE AGGREGATED ANALYTICS TABLE
-- ============================================================================
-- Merging all the summary views to create an aggregated summary table for further analysis
-- This query generates a vendor-wise sales and purchase summary, which is valuable for:
-- **Performance Optimization:**
-- - The query involves heavy joins and aggregations on large datasets like sales and purchases
-- - Storing the pre-aggregated results avoids repeated expensive computations
-- - Helps in analyzing sales, purchases, and pricing for different vendors and brands
-- - Future Benefits of Storing this data for faster Dashboarding & Reporting
-- - Instead of running expensive queries each time, dashboards can fetch data quickly

-- Drop the table if it exists (for re-running the script)
DROP TABLE IF EXISTS vendor_sales_summary;

-- Create the aggregated table using CTEs (Common Table Expressions)
CREATE TABLE vendor_sales_summary AS
WITH FreightSummary AS (
    -- CTE 1: Freight costs aggregated by vendor
    SELECT 
        vendor_number, 
        SUM(freight) AS freight_cost 
    FROM vendor_invoice 
    GROUP BY vendor_number
), 

PurchaseSummary AS (
    -- CTE 2: Purchase data joined with purchase_prices, aggregated by vendor and brand
    SELECT 
        p.vendor_number,
        p.vendor_name,
        p.brand,
        p.description,
        p.purchase_price,
        pp.price AS actual_price,
        pp.volume,
        SUM(p.quantity) AS total_purchase_quantity,
        SUM(p.dollars) AS total_purchase_dollars
    FROM purchases p
    JOIN purchase_prices pp ON p.brand = pp.brand
    WHERE p.purchase_price > 0
    GROUP BY 
        p.vendor_number, 
        p.vendor_name, 
        p.brand, 
        p.description, 
        p.purchase_price, 
        pp.price, 
        pp.volume
), 

SalesSummary AS (
    -- CTE 3: Sales data aggregated by vendor and brand
    SELECT 
        vendor_no,
        brand,
        SUM(sales_quantity) AS total_sales_quantity,
        SUM(sales_dollars) AS total_sales_dollars,
        SUM(sales_price) AS total_sales_price,
        SUM(excise_tax) AS total_excise_tax
    FROM sales
    GROUP BY vendor_no, brand
) 

-- Main SELECT: Join all three CTEs using LEFT JOINs to preserve all purchase records
-- Use COALESCE to handle NULL values from missing sales or freight data
SELECT 
    ps.vendor_number,
    ps.vendor_name,
    ps.brand,
    ps.description,
    ps.purchase_price,
    ps.actual_price,
    ps.volume,
    ps.total_purchase_quantity,
    ps.total_purchase_dollars,
    COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(ss.total_sales_dollars, 0) AS total_sales_dollars,
    COALESCE(ss.total_sales_price, 0) AS total_sales_price,
    COALESCE(ss.total_excise_tax, 0) AS total_excise_tax,
    COALESCE(fs.freight_cost, 0) AS freight_cost
FROM PurchaseSummary ps
LEFT JOIN SalesSummary ss 
    ON ps.vendor_number = ss.vendor_no 
    AND ps.brand = ss.brand
LEFT JOIN FreightSummary fs 
    ON ps.vendor_number = fs.vendor_number
ORDER BY ps.total_purchase_dollars DESC;

-- ============================================================================
--  DATA CLEANING AND VALIDATION
-- ============================================================================
-- Let's clean the data if there are any inconsistencies

-- Check data types and structure
-- PostgreSQL automatically handles data types, but let's verify the structure
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'vendor_sales_summary'
ORDER BY ordinal_position;

-- Check for NULL values in key columns
-- Note: We already used COALESCE in the table creation, but let's verify
SELECT 
    COUNT(*) AS total_records,
    COUNT(vendor_number) AS vendor_number_count,
    COUNT(brand) AS brand_count,
    COUNT(total_purchase_dollars) AS purchase_dollars_count,
    COUNT(total_sales_dollars) AS sales_dollars_count,
    COUNT(freight_cost) AS freight_cost_count
FROM vendor_sales_summary;

-- Check unique values in Volume column (should be numeric)
-- The Volume is a numerical column but may have been stored as text in source
SELECT DISTINCT volume 
FROM vendor_sales_summary 
ORDER BY volume 
LIMIT 20;

-- Check for white spaces in categorical columns
-- There may be white spaces in the categorical columns that need trimming
SELECT DISTINCT vendor_name 
FROM vendor_sales_summary 
WHERE vendor_name LIKE ' %' OR vendor_name LIKE '% ' OR vendor_name LIKE '%  %'
LIMIT 10;

SELECT DISTINCT description 
FROM vendor_sales_summary 
WHERE description LIKE ' %' OR description LIKE '% ' OR description LIKE '%  %'
LIMIT 10;

-- ============================================================================
--  DATA CLEANING - REMOVE WHITE SPACES
-- ============================================================================
-- Removing spaces from categorical columns (VendorName and Description)
-- This ensures consistent data for analysis

UPDATE vendor_sales_summary
SET vendor_name = TRIM(vendor_name),
    description = TRIM(description);

-- Verify the cleaning
SELECT 
    COUNT(*) AS records_with_leading_trailing_spaces
FROM vendor_sales_summary
WHERE vendor_name LIKE ' %' OR vendor_name LIKE '% ' 
   OR description LIKE ' %' OR description LIKE '% ';

-- ============================================================================
-- FEATURE ENGINEERING - ADD CALCULATED COLUMNS
-- ============================================================================
-- Creating new columns for better analysis
-- These metrics help in vendor selection for profitability and product pricing optimization

-- Add columns for calculated metrics
ALTER TABLE vendor_sales_summary 
ADD COLUMN IF NOT EXISTS gross_profit NUMERIC(15,2),
ADD COLUMN IF NOT EXISTS profit_margin NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS stock_turnover NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS sales_to_purchase_ratio NUMERIC(10,2);

-- Calculate Gross Profit: Sales Dollars - Purchase Dollars
UPDATE vendor_sales_summary
SET gross_profit = total_sales_dollars - total_purchase_dollars;

-- Calculate Profit Margin: (Gross Profit / Sales Dollars) * 100
-- Use NULLIF to avoid division by zero
UPDATE vendor_sales_summary
SET profit_margin = (gross_profit * 100.0 / NULLIF(total_sales_dollars, 0))
WHERE total_sales_dollars > 0;

-- Set profit margin to 0 where sales dollars is 0
UPDATE vendor_sales_summary
SET profit_margin = 0
WHERE total_sales_dollars = 0 OR total_sales_dollars IS NULL;

-- Calculate Stock Turnover: Sales Quantity / Purchase Quantity
-- Use NULLIF to avoid division by zero
UPDATE vendor_sales_summary
SET stock_turnover = total_sales_quantity::NUMERIC / NULLIF(total_purchase_quantity, 0)
WHERE total_purchase_quantity > 0;

-- Set stock turnover to 0 where purchase quantity is 0
UPDATE vendor_sales_summary
SET stock_turnover = 0
WHERE total_purchase_quantity = 0 OR total_purchase_quantity IS NULL;

-- Calculate Sales to Purchase Ratio: Sales Dollars / Purchase Dollars
-- Use NULLIF to avoid division by zero
UPDATE vendor_sales_summary
SET sales_to_purchase_ratio = total_sales_dollars / NULLIF(total_purchase_dollars, 0)
WHERE total_purchase_dollars > 0;

-- Set ratio to 0 where purchase dollars is 0
UPDATE vendor_sales_summary
SET sales_to_purchase_ratio = 0
WHERE total_purchase_dollars = 0 OR total_purchase_dollars IS NULL;

select count(*) from vendor_sales_summary;

-- checking for duplicates , as we don't have any duplicates in our data 
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY vendor_number,
                            vendor_name,
                            brand,
                            description,
                            purchase_price,
                            actual_price,
                            volume,
                            total_purchase_quantity,
                            total_purchase_dollars,
                            total_sales_quantity,
                            total_sales_dollars,
                            total_sales_price,
                            total_excise_tax,
                            freight_cost,
                            gross_profit,
                            profit_margin,
                            stock_turnover,
                            sales_to_purchase_ratio
               ORDER BY vendor_number, brand
           ) AS row_num
    FROM vendor_sales_summary
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

select volume from vendor_sales_summary limit 5;

select count(*) from vendor_sales_summary_cleaned; -- checking the new cleaned file 


