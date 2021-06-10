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

-- Analyzing product-level website pathing

select 
	website_pageviews.pageview_url,
    count(distinct website_pageviews.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_pageviews.website_session_id) as product_convt_to_order
from website_pageviews
left join orders
	on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at between '2013-02-01' and '2013-03-01'
	and website_pageviews.pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear')
group by 1;

-- assignment on product pathing analysis

-- step 1: find the relevant/products pageviews with website_session_id
-- step 2: find the next pageview id that occurs after the product pageview
-- step 3: find the pageview_url associated with any applicable next pageview_id
-- step 4 summarize the data and analyze the pre vs post periods

-- step 1: find the relevant/products pageviews with website_session_id
create temporary table products_pageviews
select
	website_session_id,
    website_pageview_id,
    created_at,
    case
		when created_at < '2013-01-06' then 'A.Pre_Product_2'
        when created_at >= '2013-01-06' then 'B. post_Product_2'
        else 'uh oh...check logic'
	end as time_period
    from website_pageviews
    where created_at < '2013-04-06' 
		and created_at > '2012-10-06'
        and pageview_url = '/products';

-- step 2: find the next pageview id that occurs after the product pageview
-- create temporary table sessions_w_next_pageview_id
select
	-- products_pageviews.time_period,
    -- products_pageviews.website_session_id,
    website_pageviews.website_pageview_id as min_next_pageview_id
from products_pageviews
	left join website_pageviews
		on website_pageviews.website_pageview_id = products_pageviews.website_pageview_id
	   and website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
group by 1;
drop table sessions_w_next_pageview_id;

select
	-- products_pageviews.time_period,
    -- products_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_next_pageview_id
from website_pageviews;


-- assignment 
-- step 1: select all pageviews for relevant sessions
-- step 2 : figure out which pageview urls to look for
-- step 3 pull all pageviews and identity th funnel steps
-- step 4 create the session- level conversion funnel view
-- step 5 aggregate the data to accss funnel performance

create temporary table sessions_seeing_product_pages
select
	website_session_id,
    website_pageview_id,
    pageview_url as product_page_seen
from website_pageviews
where created_at < '2013-04-10'
	and created_at > '2013-01-06' -- product 2 launch
    and pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear');
    
-- finding the right pageview_urls to build the funnels
select distinct
	website_pageviews.pageview_url
from sessions_seeing_product_pages
	left join website_pageviews
		on website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;
        
-- we will look at the inner querry first to look over the pageview_level results
-- then turn it into a subquerry and make it with flags
select 
	sessions_seeing_product_pages.website_session_id,
    sessions_seeing_product_pages.product_page_seen,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing-2' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from sessions_seeing_product_pages
	left join website_pageviews
		on website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
	order by
		sessions_seeing_product_pages.website_session_id,
        website_pageviews.created_at;
        
create temporary table session_product_level_made_it_flags
select
	website_session_id,
    case
		when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
        when product_page_seen = '/the-forever-love-bear' then 'lovebear'
        else 'check logic again'
	end as product_seen,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(thankyou_page) as  thankyou_madeit
from (
select 
	sessions_seeing_product_pages.website_session_id,
    sessions_seeing_product_pages.product_page_seen,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing-2' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from sessions_seeing_product_pages
	left join website_pageviews
		on website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
	order by
		sessions_seeing_product_pages.website_session_id,
        website_pageviews.created_at
        ) as pageview_level
	group by website_session_id,
		case
		when product_page_seen = '/the-original- mr-fuzzy' then 'mrfuzzy'
        when product_page_seen = '/the-forever-love-bear' then 'lovebear'
        else 'check logic again'
	end;
    
    -- final output part
select
	product_seen,
    count(distinct website_session_id) as sessions,
    count(distinct case when cart_made_it = 1 then website_session_id else null end ) as to_cart,
	count(distinct case when shipping_made_it = 1 then website_session_id else null end ) as to_shipping,
    count(distinct case when billing_made_it = 1 then website_session_id else null end ) as to_billing,
    count(distinct case when thankyou_madeit = 1 then website_session_id else null end ) as to_thankyou
from session_product_level_made_it_flags
group by product_seen;

-- then this as final output part 2 - click rates
select 
	    product_seen,
		count(distinct case when cart_made_it = 1 then website_session_id else null end )/
		count(distinct website_session_id) as product_page_click_rt,
		count(distinct case when shipping_made_it = 1 then website_session_id else null end )
		/count(distinct case when cart_made_it = 1 then website_session_id else null end ) as to_shipping_rt,
        count(distinct case when billing_made_it = 1 then website_session_id else null end )/
        count(distinct case when shipping_made_it = 1 then website_session_id else null end ) ,
        count(distinct case when thankyou_madeit = 1 then website_session_id else null end )/
        count(distinct case when billing_made_it = 1 then website_session_id else null end ) as complete_rt
from session_product_level_made_it_flags
group by product_seen