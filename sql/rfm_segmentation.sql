-- ==========================================================
-- E-Commerce Customer Segmentation & RFM Analysis Script
-- Database: PostgreSQL (Neon.tech)
-- ==========================================================


DROP VIEW IF EXISTS customer_segments;


WITH rfm_base AS (
    SELECT
        customer_id,
        -- Assuming a reference max date or current date for Recency calculation, 
        -- or using the max order date in the dataset.
        MAX(order_date) AS last_order_date,
        CURRENT_DATE - MAX(order_date) AS recency_days, -- Alternative: using max date in data
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales) AS monetary
    FROM e_commerce_transactions
    GROUP BY customer_id
),


rfm_scored AS (
    SELECT
        customer_id,
        last_order_date,
        frequency,
        monetary,
        -- For Recency: Lower days since last purchase is better (DESC order)
        NTILE(5) OVER (ORDER BY last_order_date ASC) AS r_score,
        -- For Frequency: Higher orders is better (ASC order)
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        -- For Monetary: Higher spending is better (ASC order)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),


rfm_final AS (
    SELECT
        customer_id,
        last_order_date,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score) AS rfm_total_score,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP / Loyal'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
            ELSE 'Regular / Others'
        END AS customer_segment
    FROM rfm_scored
)


CREATE VIEW customer_segments AS
SELECT * FROM rfm_final;
