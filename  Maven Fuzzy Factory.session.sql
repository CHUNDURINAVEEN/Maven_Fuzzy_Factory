--# Project : E-commerce conversion optimization 
select 
   'website_sessions' as table_name,
   count(*) as row_count,
   count(distinct website_session_id) as distinct_ids,
   min(created_at) as first_record,
   max(created_at) as last_record
from website_sessions
union all 
select 
   'website_pageviews',
   count(*),
   count(distinct website_pageview_id),
   min(created_at),
   max(created_at)
from website_pageviews
union ALL
select 
   'orders',
   count(*),
   count(distinct order_id),
   min(created_at),
   max(created_at)
from orders
order by table_name;
--# Finding pageviews without mathiching a sessions
SELECT
   count(*) as unmatched_pageviews
from website_pageviews as pv 
left join website_sessions as ws 
     on pv.website_session_id = ws.website_session_id 
where ws.website_session_id is null;
--# Finding orders with out matching a session
select 
    count(*) as unmatched_orders
from orders as o 
left join website_sessions as ws 
     on o.website_session_id = ws.website_session_id
where ws.website_session_id is null;
--# identify the first pageview inneach session 
with ranked_pageviews as (
    select
       website_session_id,
       pageview_url,
       created_at,
       row_number () over(
        partition by website_session_id
        order by created_at,website_pageview_id
       ) as pageview_rank
    from website_pageviews
),
--# keeping only firstpageview for each session 
landing_pages as (
    select
        website_session_id,
        pageview_url as landing_page
    from ranked_pageviews
    where pageview_rank = 1
),
--# count orders sepeartly for each session 
session_orders as (
    SELECT
        website_session_id,
        count(*) as order_count
    from orders
    group by website_session_id
) 
--# combine sessions with with their landing pages and orders 
select 
   ws.website_session_id,
   ws.created_at::date as session_date,
   lp.landing_page,
   coalesce(so.order_count, 0) as order_count
from website_sessions as ws
left join landing_pages as lp
     on ws.website_session_id = lp.website_session_id
left join session_orders as so
    on ws.website_session_id = so.website_session_id
order by ws.website_session_id
limit 100;
--# establish the baseline data needed for conversion KPIs.
with session_orders as (
    SELECT
       website_session_id,
       count(*) as order_count
    from orders
    group by website_session_id
),
session_level as (
    SELECT
        ws.website_session_id,
        coalesce(so.order_count,0) as order_count
    from website_sessions as ws
    left join session_orders as so 
         on ws.website_session_id = so.website_session_id
)
SELECT
   count(*) as total_sessions,
   count(distinct sl.website_session_id) as distinct_sessions,
   count(*) filter (where sl.order_count > 0) as session_with_orders,
   count(*) filter (where sl.order_count = 0) as session_without_orders,
   sum(sl.order_count) as total_orders
from session_level as sl;
--# baseline conversion rate 
with session_orders as (
    select 
       website_session_id,
       count(*) as order_count
    from orders
    group by website_session_id
),
session_level as (
    SELECT
       ws.website_session_id,
       coalesce(so.order_count,0) as order_count
    from website_sessions as ws 
    left join session_orders as so
         on ws.website_session_id = so.website_session_id
)
SELECT
   count(*) as total_sessions,
   count(*) filter (where order_count > 0) as sessions_with_orders,
   round(100.0*count(*) filter(where order_count > 0)/nullif(count(*),0),2) as conversion_rate_pct
from session_level;
--#finding matrices by landing pages 
--# rank each session pageviews chronologically
--# the pageviews ID breaks ties when timestamps identically
with ranked_pageviews as (
    SELECT
       website_session_id,
       pageview_url,
       created_at,
       row_number() over(
        partition by website_session_id
        order by created_at,website_pageview_id
       ) as pageview_rank
    from website_pageviews
),
--# keep the first page visitied in each session
landing_pages as (
    select 
       website_session_id,
       pageview_url as landing_page
    from ranked_pageviews
    where pageview_rank = 1
),
--# count orders seperatly for each session
session_orders as (
    SELECT
       website_session_id,
       count(*) as order_count
    from orders
    group by website_session_id
),
--# combining each session landing pages and order count
--# keeping session without order because we can get conversion rate accurate
session_level as (
    SELECT
       ws.website_session_id,
       lp.landing_page,
       coalesce(so.order_count,0) as order_count
    from website_sessions as ws 
    left join landing_pages as lp 
         on ws.website_session_id = lp.website_session_id
    left join session_orders as so 
        on ws.website_session_id = so.website_session_id
)
--# comparing conversion performance across the landing pages.
SELECT
   landing_page,
   count(*) as total_sessions,
   count(*) filter(where order_count>0) as session_with_orders,
   round(100.0*count(*) filter(where order_count>0)/nullif(count(*),0),2) as conversion_rate_pct
from session_level
group by landing_page
order by conversion_rate_pct desc NULLS last,total_sessions desc;
with ranked_pageviews as (
    SELECT
       website_session_id,
       pageview_url,
       created_at,
       row_number() over(
        partition by website_session_id
        order by created_at,website_pageview_id
       ) as pageview_rank
    from website_pageviews
),
--# keep the first page visitied in each session
landing_pages as (
    select 
       website_session_id,
       pageview_url as landing_page
    from ranked_pageviews
    where pageview_rank = 1
),
--# count orders seperatly for each session
session_orders as (
    SELECT
       website_session_id,
       count(*) as order_count
    from orders
    group by website_session_id
),
--# build one row per website sessions 
session_level as (
    SELECT
       ws.website_session_id,
       date_trunc('month', ws.created_at)::date as session_month,
       lp.landing_page,
       coalesce(so.order_count,0) as order_count
    from website_sessions as ws 
    left join landing_pages as lp 
         on ws.website_session_id = lp.website_session_id
    left join session_orders as so 
        on ws.website_session_id = so.website_session_id
)
--# calculating monthly conversion matrices by landing pages
SELECT
   session_month,
   landing_page,
   count(*) as total_sessions,
   count(*) filter (where order_count>0) as session_with_orders,
   round(100.0*count(*) filter(where order_count>0)/nullif (count(*),0),2) as conversion_rate_pct
from session_level
group by session_month,landing_page
order by session_month,landing_page;
--#comparing monthly sessions ,orders and conversion rates 
--# landingpage-5 higest one and landing page -3 lowest one 
with ranked_pageviews as (
    SELECT
       website_session_id,
       pageview_url,
       created_at,
       row_number() over(
        partition by website_session_id
        order by created_at,website_pageview_id
       ) as pageview_rank
    from website_pageviews
),
--# keep the first page visitied in each session
landing_pages as (
    select 
       website_session_id,
       pageview_url as landing_page
    from ranked_pageviews
    where pageview_rank = 1
),
--# count orders seperatly for each session
session_orders as (
    SELECT
       website_session_id,
       count(*) as order_count
    from orders
    group by website_session_id
),
--# build one row per website sessions 
session_level as (
    SELECT
       ws.website_session_id,
       date_trunc('month', ws.created_at)::date as session_month,
       lp.landing_page,
       coalesce(so.order_count,0) as order_count
    from website_sessions as ws 
    left join landing_pages as lp 
         on ws.website_session_id = lp.website_session_id
    left join session_orders as so 
        on ws.website_session_id = so.website_session_id
)
--# calculating monthly conversion matrices by landing pages
SELECT
   session_month,
   landing_page,
   count(*) as total_sessions,
   count(*) filter (where order_count>0) as session_with_orders,
   round(100.0*count(*) filter(where order_count>0)/nullif (count(*),0),2) as conversion_rate_pct
from session_level
where landing_page in ('/lander-5','/lander-3')
group by session_month,landing_page
order by session_month,landing_page;
-- # Measure session counts, stage conversion rates, and abandonment.
WITH session_page_flags AS (
    SELECT
        website_session_id,
        BOOL_OR(pageview_url = '/products') AS viewed_products,
        BOOL_OR(pageview_url = '/cart') AS viewed_cart,
        BOOL_OR(pageview_url = '/shipping') AS viewed_shipping,
        BOOL_OR(pageview_url = '/billing-2') AS viewed_billing,
        BOOL_OR(
            pageview_url = '/thank-you-for-your-order'
        ) AS completed_purchase
    FROM website_pageviews
    GROUP BY website_session_id
),
funnel_counts AS (
    SELECT
        COUNT(*) FILTER (
            WHERE viewed_products
        ) AS product_sessions,
        COUNT(*) FILTER (
            WHERE viewed_cart
        ) AS cart_sessions,
        COUNT(*) FILTER (
            WHERE viewed_shipping
        ) AS shipping_sessions,
        COUNT(*) FILTER (
            WHERE viewed_billing
        ) AS billing_sessions,
        COUNT(*) FILTER (
            WHERE completed_purchase
        ) AS purchase_sessions
    FROM session_page_flags
),
funnel_stages AS (
    SELECT
        1 AS stage_order,
        '1. Viewed products' AS funnel_stage,
        product_sessions AS sessions
    FROM funnel_counts
    UNION ALL
    SELECT
        2,
        '2. Viewed cart',
        cart_sessions
    FROM funnel_counts
    UNION ALL
    SELECT
        3,
        '3. Viewed shipping',
        shipping_sessions
    FROM funnel_counts
    UNION ALL
    SELECT
        4,
        '4. Viewed billing-2',
        billing_sessions
    FROM funnel_counts
    UNION ALL
    SELECT
        5,
        '5. Completed purchase',
        purchase_sessions
    FROM funnel_counts
),
funnel_metrics AS (
    SELECT
        stage_order,
        funnel_stage,
        sessions,
        LAG(sessions) OVER (
            ORDER BY stage_order
        ) AS previous_stage_sessions
    FROM funnel_stages
)
SELECT
    funnel_stage,
    sessions,
    previous_stage_sessions,
    ROUND(
        100.0 * sessions
        / NULLIF(previous_stage_sessions, 0),
        2
    ) AS conversion_from_previous_stage_pct,
    ROUND(
        100.0 * (
            previous_stage_sessions - sessions
        )
        / NULLIF(previous_stage_sessions, 0),
        2
    ) AS dropoff_from_previous_stage_pct
FROM funnel_metrics
ORDER BY stage_order;