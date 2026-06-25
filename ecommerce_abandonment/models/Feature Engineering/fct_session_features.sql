/* business question : 
"How much money is actually sitting in abandoned carts?"
*/

{{ config(
    materialized='table',
    format='parquet'
) }}

WITH aggs AS (
    SELECT * FROM {{ ref('stg_ecommerce_cleaned') }}
),

raw_data AS (
    -- STEP 1: Load data once into memory
    SELECT
        user_id,
        user_session,
        event_type,
        price,
        CAST(event_time AS TIMESTAMP) AS event_time,
        category_code
    FROM aggs
),

category_intelligence AS (
    -- STEP 2: The "Price Insensitivity" Baseline
    -- Calculate the 90th percentile price and average price for EVERY category across the whole store
    SELECT
        category_code,
        -- JARVIS FIX: Athena's clean function for percentiles
        APPROX_PERCENTILE(price, 0.90) AS category_p90_price,
        AVG(price) AS category_avg_price
    FROM raw_data
    WHERE category_code IS NOT NULL
    GROUP BY category_code
),

session_events AS (
    -- STEP 3: Establish the timeline
    SELECT
        r.user_id,
        r.user_session,
        r.event_type,
        r.price,
        r.event_time,
        r.category_code,
        c.category_p90_price, 
        c.category_avg_price,

        MIN(CASE WHEN r.event_type = 'cart' THEN r.event_time END) OVER (PARTITION BY r.user_session) AS first_cart_time,
        MAX(CASE WHEN r.event_type = 'cart' THEN r.event_time END) OVER (PARTITION BY r.user_session) AS last_cart_time,
        MIN(CASE WHEN r.event_type = 'view' THEN r.event_time END) OVER (PARTITION BY r.user_session) AS first_view_time

    FROM raw_data r
    LEFT JOIN category_intelligence c ON r.category_code = c.category_code
),

session_agg AS (
    -- STEP 4: Aggregate based on the timeline
    SELECT
        user_id,
        user_session,

        MIN(event_time) AS session_start_time,
        MAX(event_time) AS session_end_time,

        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase,

        SUM(CASE WHEN event_type = 'view' THEN price ELSE 0 END) AS total_viewed_value,
        SUM(CASE WHEN event_type = 'cart' THEN price ELSE 0 END) AS net_cart_value,
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END) AS total_purchased_value,
       
       -- TOTAL Views Up to Last Cart (For accurate Overthinking Ratio)
        SUM(CASE WHEN event_type = 'view' AND event_time <= last_cart_time THEN 1 ELSE 0 END) AS total_views_up_to_last_cart,
        SUM(CASE WHEN event_type = 'view' AND event_time > last_cart_time THEN 1 ELSE 0 END) AS views_after_last_cart,
        COUNT(DISTINCT category_code) AS unique_categories_viewed,
        
        -- JARVIS FIX: Switched to date_diff
        GREATEST(0, MAX(date_diff('second', first_view_time, last_cart_time))) AS time_to_cart_sec,
        
        -- JARVIS FIX: Added this back so your 'is_premium_shopper = 1' logic doesn't crash the pipeline
        MAX(CASE WHEN event_type = 'cart' AND price >= category_p90_price THEN 1 ELSE 0 END) AS is_premium_shopper

    FROM session_events
    GROUP BY user_id, user_session
),

triage_classification AS (
    -- STEP 5: Final Output with Formatting and Triage Status
    SELECT
        *,

        -- JARVIS FIX: Athena's syntax for date truncation
        date_trunc('month', session_start_time) AS session_month,
        
        -- JARVIS FIX: Completely rewrote the time formatting math for AWS
        CASE
            WHEN time_to_cart_sec IS NOT NULL AND time_to_cart_sec >= 0 THEN
                CAST(FLOOR(time_to_cart_sec / 86400) AS VARCHAR) || 'd:' ||
                LPAD(CAST(FLOOR(MOD(time_to_cart_sec, 86400) / 3600) AS VARCHAR), 2, '0') || 'h:' ||
                LPAD(CAST(FLOOR(MOD(time_to_cart_sec, 3600) / 60) AS VARCHAR), 2, '0') || 'm:' ||
                LPAD(CAST(MOD(time_to_cart_sec, 60) AS VARCHAR), 2, '0') || 's'
            ELSE '0d:00h:00m:00s'
        END AS time_to_cart_formatted,
        
        -- THE TRIAGE ENGINE
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

-- STEP 6: The Financial Metrics Layer
SELECT 
    *,
    CASE WHEN status = 'Safe Buyer' THEN total_purchased_value * 0.10 ELSE 0.00 END AS protected_margin,
    CASE WHEN status = 'Hesitate Buyer (Abandoned)' THEN net_cart_value ELSE 0.00 END AS recoverable_revenue,
    CASE WHEN has_purchase = 0 THEN net_cart_value ELSE 0.00 END AS revenue_bleed,
    CASE WHEN status = 'Hesitate Buyer (Purchased)' THEN total_purchased_value ELSE 0.00 END AS friction_revenue

FROM triage_classification