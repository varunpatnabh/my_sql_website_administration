select 
	primary_product_id,
    count(distinct order_id) as orders,
    sum(price_usd) as revenue,
    sum(price_usd - cogs_usd) as margin,
    avg(price_usd) as aov
from orders
group by 1
order by 2 desc;

-- assignment on product level sales

select 
	year(created_at) as yr,
    month(created_at) as mo,
    count(distinct order_id) as no_of_sales,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin_generated
from orders
where created_at < '2013-01-04'
group by 1,2;

-- assignment on product launch analysis

select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mon,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session,
    count(distinct case when primary_product_id = 1 then order_id else null end) as product_one_orders,
    count(distinct case when primary_product_id = 2 then order_id else null end) as product_two_orders

from website_sessions
left join orders
	on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at between '2012-04-01' and '2013-04-05'
group by 1, 2;
select * from orders