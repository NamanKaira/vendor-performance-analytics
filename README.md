📊 Vendor Performance Analytics
📌 Project Overview

This project delivers an end-to-end vendor performance analytics solution to evaluate procurement efficiency, sales profitability, and inventory health.
The workflow integrates PostgreSQL, Python, and Power BI to transform raw transactional data into actionable business insights.

🗂️ Data Sources

The analysis is based on 4 raw CSV datasets loaded into PostgreSQL:

purchases – procurement transactions and quantities

purchase_prices – vendor pricing and product details

vendor_invoice – invoice-level spend and freight costs

sales – product-level sales transactions

🏗️ Architecture & Workflow
CSV Files
   ↓
PostgreSQL (Raw Tables)
   ↓
SQL Aggregations & Feature Engineering
   ↓
vendor_sales_summary (8,500+ rows)
   ↓
Python (EDA, Cleaning, Statistics)
   ↓
vendor_sales_summary_cleaned
   ↓
Power BI Dashboard

🧮 Data Modeling & Feature Engineering

Using SQL (CTEs, joins, aggregations), a consolidated analytics table was created with 15+ KPIs, including:

Total Sales & Purchase Dollars

Gross Profit & Profit Margin (%)

Stock Turnover Ratio

Sales-to-Purchase Ratio

Purchase Contribution (%) per Vendor

Unsold Inventory Quantity & Value

📊 Python Analysis (Jupyter Notebook)

Data validation, type correction, and filtering of inconsistent records

Exploratory Data Analysis (EDA): distributions, outliers, correlations

Vendor & brand performance analysis

Bulk purchasing vs unit price analysis

Inventory efficiency and unsold capital estimation

Statistical analysis:

95% confidence intervals

Two-sample t-test comparing profit margins of top vs low-performing vendors

Cleaned data was written back to PostgreSQL using SQLAlchemy for BI consumption.

📈 Power BI Dashboard

An interactive dashboard was built on the cleaned analytics table, featuring:

KPI cards: Total Sales, Purchases, Gross Profit, Profit Margin %, Unsold Capital

Top vendors and brands by sales

Vendor purchase contribution (Pareto analysis)

Low inventory turnover vendor identification

High-margin but low-sales brand detection

Drill-downs and filters for vendor-level insights

🛠️ Tech Stack

Database: PostgreSQL

Data Analysis: Python (Pandas, NumPy, Seaborn, Matplotlib, SciPy)

Data Connectivity: SQLAlchemy

Visualization & BI: Power BI

Environment: Jupyter Notebook

🚀 Key Business Insights

Identified top 10 vendors contributing ~65% of total procurement spend, highlighting vendor dependency risk

Detected high-margin, low-sales brands suitable for targeted promotions

Flagged low inventory turnover vendors with excess stock

Estimated $2.7M+ capital locked in unsold inventory

📁 Repository Structure
vendor-performance-analytics/
│
├── sql/
│   ├── vendor_sales_summary.sql
│   
│
├── notebooks/
│   ├── vendor_analysis_eda.ipynb
│
├── powerbi/
│   ├── vendor_performance_dashboard.pbix
│
├── data/
│   ├── purchases.csv
│   ├── purchase_prices.csv
│   ├── vendor_invoice.csv
│   ├── sales.csv
│
└── README.md

🎯 Use Case

This project supports data-driven procurement and inventory decisions by improving visibility into vendor performance, pricing efficiency, and stock utilization.

🎯 Use Case

This project supports data-driven procurement and inventory decisions by improving visibility into vendor performance, pricing efficiency, and stock utilization.
