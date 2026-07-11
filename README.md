# 🛒 Promotional Waste Audit: Cart Abandonment & Margin Optimization

<p>
  <img src="https://img.shields.io/badge/Google%20BigQuery-669DF6?style=flat&logo=google-cloud&logoColor=white" alt="BigQuery">
  <img src="https://img.shields.io/badge/AWS%20Athena-232F3E?style=flat&logo=amazon-aws&logoColor=white" alt="AWS Athena">
  <img src="https://img.shields.io/badge/dbt_Cloud-FF6B6B?style=flat&logo=dbt&logoColor=white" alt="dbt Cloud">
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/SQL-4479A1?style=flat&logo=postgresql&logoColor=white" alt="SQL">
  <img src="https://img.shields.io/badge/Power_BI-F2C811?style=flat&logo=powerbi&logoColor=black" alt="Power BI">
</p>

*An independent enterprise-architecture case study demonstrating multi-cloud ELT workflows, behavioral intent classification, and data-driven margin optimization.*

---

## 🎯 The Business Problem: The $7 Million Bleed

Imagine a high-growth e-commerce startup generating $10 million in annual revenue. A top-level analytics audit reveals a critical bottleneck: a **70% cart abandonment rate**. Users are essentially leaving $7 million worth of products in their digital carts and walking away.

However, the high abandonment rate was only a symptom. The root cause of the financial drain was the company's **"dumb discount system."** In a desperate attempt to recover abandoned carts, the platform was automatically triggering a 10% discount pop-up and sending 24-hour reminder emails to *every single user*. 

This spray-and-pray approach resulted in a massive, two-fold financial bleed:
* **Margin Erosion (Setting Profit on Fire):** The system was unintentionally giving 10% discounts to "Safe Buyers"—users who had high intent and were going to check out at full price anyway. 
* **Wasted Ad Spend (Plummeting ROAS):** The marketing team was burning their paid retargeting budget on "Window Shoppers"—users who used the cart as a wishlist with absolutely zero purchase intent.

**The Objective:**
The company possessed the raw clickstream data, but lacked a rule-based diagnostic engine to classify user intent. They required an automated framework to determine exactly *who* should receive a discount to recover a sale, and more importantly, *who should be blocked* from discounts to protect profit margins.

---

## ⚙️ Core Analytical Execution & Intent Classification

To translate this business problem into actionable data logic, I engineered a behavioral classification model using session logs and cart events, breaking the pipeline into four strategic pillars:

1. **Establishing the Baseline (Total Revenue at Risk):** Before applying algorithms, I quantified the exact size of the problem. By filtering session logs where `event_type = 'cart'` without a subsequent `purchase` event, I aggregated the total pipeline value at risk. This established the primary financial KPI—you cannot fix a problem without proving its scale first.
2. **Plugging the Margin Bleed (The "Safe Buyers"):** Analyzed session velocity and category focus. Users who navigated directly to specific categories and added to their cart rapidly demonstrated high purchase intent. The engine tags these users to **block discount triggers**, ensuring they convert at full price and immediately saving profit margins.
3. **Surgical Rescue Targeting (The "Hesitant Buyers"):** Engineered a 'Browse-to-Cart Ratio' metric. Users who viewed 15+ items over an extended session before adding to the cart were flagged as price-shopping or hesitant. The system signals the marketing engine to trigger the 10% recovery pop-up *only* for this highly receptive segment.
4. **Filtering the Noise (The "Window Shoppers"):** Identified behavioral anomalies, such as users with absurdly high cart values (e.g., $15,000) containing 40+ disparate items. These profiles are tagged as 'Stagnant' and systematically excluded from both discount triggers and paid ad retargeting campaigns, directly decreasing Customer Acquisition Cost (CAC) and improving overall return on ad spend.

---
## ELT Architecture and Data flow
### Google Bigqury :
<img width="1529" height="991" alt="cart_google" src="https://github.com/user-attachments/assets/6d32ba78-9897-428d-b6b8-dd6628fbb55d" />


### AWS ATHENA 
<img width="1141" height="621" alt="cart_security drawio" src="https://github.com/user-attachments/assets/f8d7d80c-8e35-4312-adc6-44d328fd5535" />


<img width="2459" height="1551" alt="cart_architecture drawio" src="https://github.com/user-attachments/assets/5fcce41a-54a1-44a3-846d-c272dc441695" />

---

## 📊 Raw Data Sourcing & Scale

This project is built to handle massive, production-grade data volumes. The raw dataset consists of seven months of logged activity (October 2019 to April 2020), originally stored as highly compressed `.csv.gz` files. 

To demonstrate scalability and cloud-compute efficiency, the pipeline processes **over 411 Million rows** of raw data.

### Data Volume Breakdown

| Period | File Name | Compressed Size | Total Rows |
| :--- | :--- | :--- | :--- |
| **Oct 2019** | `2019-Oct.csv.gz` | 42,448,764 |
| **Nov 2019** | `2019-Nov.csv.gz` | 67,501,979 |
| **Dec 2019** | `2019-Dec.csv.gz` | 67,542,878 |
| **Jan 2020** | `2020-Jan.csv.gz` | 55,967,041 |
| **Feb 2020** | `2020-Feb.csv.gz` | 55,318,565 |
| **Mar 2020** | `2020-Mar.csv.gz` | 56,341,241 |
| **Apr 2020** | `2020-Apr.csv.gz` | 66,589,268 |
| **Total Scale** | **7 Months**  | **411,709,736 Rows** |

<img width="1908" height="830" alt="image" src="https://github.com/user-attachments/assets/ad24267c-08ae-42eb-8ea9-a68275b6c144" />

--
## dbt Data Lineage & Transformation DAG
<img width="891" height="951" alt="dbt_lineage drawio" src="https://github.com/user-attachments/assets/f5a31509-c403-4dc7-acfd-9194ca539909" />

--
## 🗂️ Repository Structure & SQL Models

This project utilizes **dbt (data build tool)** to execute modular SQL transformations directly within the cloud compute engine. The modeling architecture follows industry-standard data warehousing principles, separating raw data ingestion from business logic and feature engineering.

Below is the core structure of the dbt `models/` directory:

```text
ecommerce_abandonment/
├── dbt_project.yml                 # Core dbt configuration and materialization settings
└── models/
    ├── sources.yml                 # Maps the cloud data catalog (schema) to dbt
    ├── stg_ecommerce_unified.sql   # Base staging model targeting the 411M+ raw rows
    │
    ├── cleaning/
    │   └── stg_ecommerce_cleaned.sql # Handles type casting, null imputation, and deduplication
    │
    ├── Feature Engineering/
    │   └── fct_session_features.sql  # Aggregates granular clicks into session-level metrics
    │
    └── model_features.sql          # Final wide denormalized table built for BI/ML ingestion
```
---
### 🧠 Core Engineering Logic: Behavioral Triage Engine (Demo Snippet)

📌 *Note: The snippet below is a demonstration highlighting the core logic. The complete dbt models within this repository heavily utilize advanced SQL techniques including complex `CTEs`, conditional `AGGREGATIONS`, dynamic `CASE` statements, and analytical `WINDOW` functions to execute heavy data transformations directly within AWS Athena.*

The true value of this Session Analysis lies in moving beyond simple binary flags (purchased vs. abandoned). Below is the logic snippet that dynamically classifies users based on their session timeline (Time-to-Cart) and exploration behavior, ultimately calculating the exact recoverable revenue and financial bleed for the business.

```sql
-- Snippet from: models/Feature Engineering/fct_session_features.sql

WITH triage_classification AS (
    -- Dynamically segments users based on checkout velocity and browsing friction
    SELECT
        *,
        CASE 
            WHEN has_purchase = 1 THEN 
                CASE 
                    WHEN time_to_cart_sec < 180 AND unique_categories_viewed <= 1 AND views_after_last_cart <= 1 
                    THEN 'Safe Buyer'
                    ELSE 'Hesitate Buyer (Purchased)'
                END

            WHEN has_purchase = 0 THEN
                CASE 
                    WHEN time_to_cart_sec < 300 AND unique_categories_viewed <= 3 AND total_views_up_to_last_cart <= 6 
                    THEN 'Hesitate Buyer (Abandoned)'
                    ELSE 'Window Shopper'
                END
        END AS status
    FROM session_agg
    WHERE has_cart = 1
)

SELECT 
    user_id,
    user_session,
    status,
    -- Translates behavioral segments into actionable financial metrics
    CASE WHEN status = 'Safe Buyer' THEN total_purchased_value * 0.10 ELSE 0.00 END AS protected_margin,
    CASE WHEN status = 'Hesitate Buyer (Abandoned)' THEN net_cart_value ELSE 0.00 END AS recoverable_revenue,
    CASE WHEN has_purchase = 0 THEN net_cart_value ELSE 0.00 END AS revenue_bleed,
    CASE WHEN status = 'Hesitate Buyer (Purchased)' THEN total_purchased_value ELSE 0.00 END AS friction_revenue
FROM triage_classification;

```
---
## 📈 Final Deliverable: Business Intelligence & Actionable Insights
https://app.powerbi.com/view?r=eyJrIjoiOWE2ODY3Y2ItNGM1Yi00ZDhhLTk4ZGUtNDQ3YTI0ZTc2ZTYyIiwidCI6IjM0YmQ4YmVkLTJhYzEtNDFhZS05ZjA4LTRlMGEzZjExNzA2YyJ9 

---
## 📁 Data Sourcing & Simulation

To ensure strict adherence to data privacy standards and completely separate this independent case study from any professional work experience, the raw clickstream and event data powering this architecture is a synthetically scaled version of a public dataset: [eCommerce Behavior Data from Multi Category Store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store).

The raw data was structurally modified, aggregated across multiple event types (views, carts, purchases), and scaled to simulate a massive enterprise multi-cloud environment. This allowed me to rigorously stress-test the AWS + BigQuery + dbt ELT pipeline and demonstrate production-grade analytical capabilities without utilizing proprietary company data.
