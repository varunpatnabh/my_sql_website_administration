/* -- Part 1: to see our volume growth. can you pull overall session and order volume,
trended by quarter for the life of buisness? Since the most recent quarter is incomplete,
you can decide how to handle it.
*/

select 
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;

/*
2. next, lets show case all of our efficiency improvments. i would love to show  quartely figures
Since we launched, for session-to-order conversion rate, revenue per order, and revenue per session
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_cvr_rate,
    sum(price_usd)/count(distinct orders.order_id) as revenue_per_order,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;

/*
3. i'd like to show how we've grown specific channels.Could you pull a quaterly view of
orders from gsearch nonbrand, bsearch nonbrand, brand search overall , organic search, and direct_type_in?
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as gsearch_nonbrand,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as bsearch_nonbrand,
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end ) as brand_search_overall,
    count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end) as organic_search_orders,
	count(distinct case when utm_source is null and http_referer is  null then orders.order_id else null end) as direct_type_in
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
	group by 1,2
    order by 1,2;
    
/*
4. Next, lts show the overall session_to_order conversion rate trends for those sanme channels by quarter.
plese also make a note of any periods where we made major improvements or optimizations.
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as gsearch_nonbrand_conv,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as bsearch_nonbrand_conv,
	count(distinct case when utm_campaign = 'brand' then orders.order_id else null end )
		/count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end ) as brand_search_conv,
	count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end)
		/count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_conv_rate,
	count(distinct case when utm_source is null and http_referer is  null then orders.order_id else null end)
		/count(distinct case when utm_source is null and http_referer is  null then website_sessions.website_session_id else null end) as direct_type_in_conv
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;

/*
5. We've come a long way since the days of selling a single product.Let's pull monthly trending for revenue
and margin by product, along with total sales and revenue, note anything you notice bout seasonality.
*/

select
	year(created_at) as yr,
    quarter(created_at) as qtr,
    sum(case when product_id= 1 then price_usd else null end) as mrfuzzy_rev,
    sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrfuzzy_margin,
    sum(case when product_id= 2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id = 2 then price_usd - cogs_usd else null end) as lovebear_margin,
    sum(case when product_id= 3 then price_usd else null end) as birthdaybear_rev,
    sum(case when product_id = 3 then price_usd - cogs_usd else null end) as birthdaybear_margin,
    sum(case when product_id= 4 then price_usd else null end) as minibear_rev,
    sum(case when product_id = 4 then price_usd - cogs_usd else null end) as minibear_margin,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2
order by 1,2;

/*
6.let's dive deeper into the impact of introducing new products. please pull monthly sessions to
the /roducts page, and show how the % of thse clicking session through another page has changed 
over time along with a view of how converstion from /products to placing an order has improved.
*/

-- first identify all the views of the /products page

create temporary table product_pageviews
select
	website_session_id,
    website_pageview_id,
    created_at as saw_product_page_at
from website_pageviews
where pageview_url = '/products';

select 
	year(saw_product_page_at) as yr,
    month(saw_product_page_at) as mo,
    count(distinct product_pageviews.website_session_id) as session_to_product_page,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page,
    count(distinct website_pageviews.website_session_id)/count(distinct product_pageviews.website_session_id) as clickthrough_rt,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct product_pageviews.website_session_id) as products_to_order_rt
from product_pageviews
	left join website_pageviews
		on website_pageviews.website_session_id = product_pageviews.website_session_id -- same session
        and website_pageviews.website_pageview_id > product_pageviews.website_pageview_id -- they hd another page after
	left join orders
		on orders.website_session_id = product_pageviews.website_session_id
group by 1,2;


/*
7. we made our 4th product available as a primary product on december 05,2014(it was previously only a cross-sell
item). could you pull data science then , and show how well each product cross-sells product from one another?
*/

create temporary table primary_products
select 
	order_id,
    primary_product_id,
    created_at as ordered_at
from orders
where created_at > '2014-12-05' -- when the 4rth product added sounds like 
;
-- cross sell analysis
select
	primary_product_id,
    count(distinct order_id) as total_orders,
    count(distinct case when cross_sell_product_id = 1 then order_id else null end) as _xsold_p1,
	count(distinct case when cross_sell_product_id = 2 then order_id else null end) as _xsold_p2,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end) as _xsold_p3,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end) as _xsold_p4,
    count(distinct case when cross_sell_product_id = 1 then order_id else null end)/count(distinct order_id) as p1_xsell_rt,
	count(distinct case when cross_sell_product_id = 2 then order_id else null end)/count(distinct order_id) as p2_xsell_rt,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end)/count(distinct order_id) as p3_xsell_rt,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end)/count(distinct order_id) as p4_xsell_rt

from 
(
select
	primary_products.*,
    order_items.product_id as cross_sell_product_id
from primary_products
	left join order_items
		on order_items.order_id = primary_products.order_id
    and order_items.is_primary_item = 0 -- only bringing in cross sells
) as primary_w_cross_sell
group by 1;

/*
8. In addition to telling