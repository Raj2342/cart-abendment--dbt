{{ config(
    materialized='table',
    format='parquet'
) }}

WITH raw_events AS (
    SELECT * FROM {{ ref('stg_ecommerce_cleaned') }}
),

-- Step 1: Session ke sabhi important timestamps aur ML flags nikalna
session_timeline AS (
    SELECT
        user_session,
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MAX(CASE WHEN event_type = 'cart' THEN event_time END) AS last_cart_time,
        
        -- Target Labels (has_purchase) & Filters (has_cart)
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM raw_events
    GROUP BY user_session, user_id
),

-- Step 2: 3-Phase Feature Engineering 
feature_engineering AS (
    SELECT
        t.user_id,
        t.user_session,

        -- Ye Step 1 mein pehle se nikal chuke hain, dubara calculate karne ki zaroorat nahi
        MAX(t.has_view) AS has_view,
        MAX(t.has_cart) AS has_cart,
        MAX(t.has_purchase) AS has_purchase,
        
        -- TOTAL Views Up to Last Cart
        SUM(CASE WHEN r.event_type = 'view' AND r.event_time <= t.last_cart_time THEN 1 ELSE 0 END) AS total_views_up_to_last_cart,
        
        -- Phase 3: THE HESITATION ZONE
        COALESCE(SUM(CASE WHEN r.event_type = 'view' AND r.event_time > t.last_cart_time THEN 1 ELSE 0 END), 0) AS views_after_last_cart,
        
        -- Depth & Breadth (Up to Last Cart)
        COALESCE(COUNT(DISTINCT CASE WHEN r.event_time <= t.last_cart_time THEN r.category_code END), 0) AS unique_categories_viewed,
        COALESCE(COUNT(DISTINCT CASE WHEN r.event_type = 'view' AND r.event_time <= t.last_cart_time THEN r.product_id END), 0) AS unique_products_viewed_total,
        
        -- Decision Speed
        -- JARVIS FIX: Swapped TIMESTAMP_DIFF for date_diff
        COALESCE(GREATEST(0, MAX(date_diff('second', t.first_view_time, t.last_cart_time))), 0) AS time_to_cart_sec

    FROM session_timeline t
    JOIN raw_events r ON t.user_session = r.user_session
    WHERE t.first_cart_time IS NOT NULL -- Model sirf unpar train hoga jinhone cart banaya
    GROUP BY t.user_session, t.user_id
)

-- Step 3: Final Output with Overthinker Ratio
SELECT 
    *,
    -- JARVIS FIX: Removed SAFE_DIVIDE and replaced with standard division using NULLIF
    COALESCE(CAST(total_views_up_to_last_cart AS DOUBLE) / NULLIF(unique_products_viewed_total, 0), 0) AS overthinker_ratio,
    
    CASE 
        -- Class 0: Safe Buyer
        WHEN has_purchase = 1 
             AND time_to_cart_sec < 180 
             AND unique_categories_viewed <= 1 
             AND views_after_last_cart <= 1 
             AND total_views_up_to_last_cart <= 5 
        THEN 0
        
        -- Class 2: THE HESITATOR 
        -- JARVIS FIX: Removed SAFE_DIVIDE here too
        WHEN COALESCE(CAST(total_views_up_to_last_cart AS DOUBLE) / NULLIF(unique_products_viewed_total, 0), 0) > 3
             OR time_to_cart_sec > 180 
             OR total_views_up_to_last_cart > 6
             OR views_after_last_cart > 2 
        THEN 2
        
        -- Class 1: Window Shopper
        ELSE 1 
    END AS target_label

FROM feature_engineering