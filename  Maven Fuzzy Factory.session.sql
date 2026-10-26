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
--# check the consistency of the url-based funnel.
with session_page_flags as (
    SELECT
       website_session_id,
       bool_or(pageview_url = '/products') as viewed_products,
       bool_or(pageview_url ='/cart') as viewed_cart,
       bool_or(pageview_url = '/shipping') as viewed_shipping,
       bool_or(pageview_url = '/billing-2') as viewed_billing,
       bool_or(pageview_url = '/thank_you_for_your_order') as completed_purchase
    from website_pageviews
    group by website_session_id
)
SELECT
   count(*) filter(where viewed_cart and not viewed_products) as cart_with_out_products,
   count(*) filter(where viewed_shipping and not viewed_cart) as shipping_with_out_cart,
   count(*) filter(where viewed_billing and not viewed_shipping) as billing_with_out_shipping,
   count(*) filter(where completed_purchase and not viewed_billing) as purchase_with_out_billing
from session_page_flags;
--# identify product-related page urls
SELECT
   pageview_url,
   count(*) as total_pageviews,
   count(distinct website_session_id) as unique_sessions
from website_pageviews
where pageview_url like '%product%'
    or pageview_url like '%cart%'
group by pageview_url
order by total_pageviews desc;
--# inspect product and otheritem data
SELECT
   table_name, 
   column_name, 
   data_type
from information_schema.columns
where table_schema = 'public'
   and table_name in ('products','order_items')
order by table_name,ordinal_position;
--# compare product-level sales and financial performance
select
    p.product_id,
    p.product_name,
    count(oi.order_item_id) as units_sold,
    round(sum(oi.price_usd),2) as total_revenue,
    round(sum(oi.cogs_usd),2) as total_cost,
    round(sum(oi.price_usd - oi.cogs_usd),2) as total_profit,
    round(100.0*sum(oi.price_usd-oi.cogs_usd)/nullif(sum(oi.price_usd),0),2) as profit_margin_pct
from products p
join order_items oi 
   on p.product_id = oi.product_id
group by p.product_id,p.product_name
order by total_revenue desc;
--# verify product profit margins
SELECT
   p.product_name,
   round(sum(oi.price_usd),2) as revenue,
   round(sum(oi.cogs_usd),2) as total_cost,
   round(sum(oi.price_usd - oi.cogs_usd),2) as profit,
   round(100.0*sum(oi.price_usd - oi.cogs_usd)/nullif(sum(oi.price_usd),0),2) as profit_margin_pct
from products p 
join order_items oi 
   on p.product_id = oi.product_id
group by product_name
order by revenue desc;
--# inspect visitor segment fields
SELECT
   column_name,
   data_type
from information_schema.columns
where table_schema = 'public'
   and table_name = 'website_sessions'
order by ordinal_position; 
--# traffic-source conversion analysis
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
       coalesce(ws.utm_source,'unknown') as utm_source,
       coalesce(ws.utm_campaign,'unknown') as utm_campaign,
       coalesce(so.order_count,0) as order_count
    from website_sessions ws
    left join session_orders so 
         on ws.website_session_id = so.website_session_id
)
SELECT
   utm_source,
   utm_campaign,
   count(*) as total_sessions,
   count(*) filter(where order_count>0) as session_with_orders,
   round(100.0*count(*) filter(where order_count>0)/nullif(count(*),0),2) as conversion_rate_pct
from session_level
group by utm_source,utm_campaign
order by conversion_rate_pct desc,total_sessions desc;
--# device-type conversion analysis
--# finding desktop and device sessions jave different or not 
with session_orders as (
    select 
        website_session_id,
        count(*) as order_count
    from orders
    group by website_session_id
)
SELECT
    coalesce(ws.device_type,'unknown') as device_type,
    count(*) as total_sessions,
    count(*) filter(where coalesce(so.order_count,0)>0) as session_with_orders,
    round(100.0*(count(*) filter(where coalesce(so.order_count,0)>0))/nullif(count(*),0),2) as conversion_rate_pct
from website_sessions ws 
left join session_orders so 
     on ws.website_session_id = so.website_session_id
group by coalesce(ws.device_type,'unknown')
order by conversion_rate_pct desc;
--# new vs returning visitors conversion 
with session_orders as (
    select 
        website_session_id,
        count(*) as order_count
    from orders
    group by website_session_id
)
select 
   case
    when ws."is_repeat-session" = 1 then 'returning'
    when ws."is_repeat-session" = 0 then 'new'
    else 'unknown'
   end as visitor_type,
   count(*) as total_sessions,
   count(*) filter(where coalesce(so.order_count,0)>0) as sessions_with_orders,
   round(100.0*count(*) filter(where coalesce(so.order_count,0)>0)/nullif(count(*),0),2) as conversion_rate_pct
from website_sessions ws 
left join session_orders so 
     on ws.website_session_id = so.website_session_id
group by 
    CASE
     when ws."is_repeat-session" = 1 then 'returning'
     when ws."is_repeat-session" = 0 then 'new'
     else 'unknown'
    end 
order by conversion_rate_pct desc;