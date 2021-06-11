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
group by product_seen;

-- CROSS SELLING AND PRODUCT PORTFOLIO ANALYSIS

SELECT 	
	orders.primary_product_id,
    count(distinct orders.order_id),
    count(distinct case when order_items.product_id = 1 then orders.order_id else null end ) as x_sell_pd1,
    count(distinct case when order_items.product_id = 2 then orders.order_id else null end ) as x_sell_pd2,
    count(distinct case when order_items.product_id = 3 then orders.order_id else null end ) as x_sell_pd3,
    
    count(distinct case when order_items.product_id = 1 then orders.order_id else null end ) 
    / count(distinct orders.order_id) as x_sell_pd1_rt	,
    count(distinct case when order_items.product_id = 2 then orders.order_id else null end ) 
    / count(distinct orders.order_id) as x_sell_pd2_rt	,
    count(distinct case when order_items.product_id = 3 then orders.order_id else null end ) 
    / count(distinct orders.order_id) as x_sell_pd3_rt	
    
from orders
	left join order_items
    on order_items.order_id = orders.order_id
    -- and order_items.is_primary_item = 0 -- x sell

where orders.order_id between 10000 and 11000
	and order_items.is_primary_item = 0

group by 1;

-- Assignment on cross sell analysis

-- step 1 : identify the relevant cart page views and their sessions
-- step 2 see which of those / cart sessions clicked through to the shipping page
-- step 3 : find the orders associated with the / cart sessions, Analyze products purchased, AOV
-- step 4 : Aggregate and analyze a summary of our findings

create temporary table sessions_seeing_cart
select 
	case 
		when created_at < '2013-09-25' then 'A. Pre_Cross_Sell'
        when created_at >= '2013-01-06' then 'B. Post_Cross_Sell'
        else 'check logic'
	end as time_period,
    website_session_id AS cart_session_id,
    website_pageview_id as cart_pageview_id
from website_pageviews
where created_at between '2013-08-25' and '2013-10-25'
	and pageview_url ='/cart';
    

create temporary table cart_sessions_seeing_another_page
select
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    min(website_pageviews.website_pageview_id) as pv_id_after_cart
from sessions_seeing_cart
	left join website_pageviews
    on website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
    and website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
group by 1,2
having
	min(website_pageviews.website_pageview_id) is not null;
    
 create temporary table pre_post_sessions_orders
select
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
from sessions_seeing_cart
	inner join orders
		on sessions_seeing_cart.cart_session_id = orders.website_session_id;
        
-- first we will look  at this select statement
-- then we will turn it into a subuerry

select
	
  sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    case when cart_sessions_seeing_another_page.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
    case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
from sessions_seeing_cart
	left join cart_sessions_seeing_another_page
     on sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	left join pre_post_sessions_orders
		on sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
	group by
		cart_session_id;
        
select
	time_period,
    count(distinct cart_session_id) as cart_sessions,
    sum(clicked_to_another_page) as cliclthroughs,
    sum(clicked_to_another_page)/count(distinct cart_session_id) as cart_ctr,
    sum(placed_order) as orders_placed,
    sum(items_purchased) as products_purchased,
    sum(items_purchased)/sum(placed_order) as products_per_order,
    sum(price_usd) as revenue,
    sum(price_usd)/sum(placed_order) as aov,
    sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
from(
select
	
  sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    case when cart_sessions_seeing_another_page.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
    case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
from sessions_seeing_cart
	left join cart_sessions_seeing_another_page
     on sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	left join pre_post_sessions_orders
		on sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
	group by
		cart_session_id
) as full_data
group by time_period;

-- assignment on product portfolio analysis

select 
	case 
		when website_sessions.created_at <'2013-12-12' then  'A. Pre_Birthday_Bear'
        when website_sessions.created_at >= '2013-12-12' then 'B. Post_Birthday_Bear'
        else 'check logic'
	end as time_period,
--  count(distinct website_sessions.website_session_id) as sessions,
 -- count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
--  sum(orders.price_usd) as total_revenue,
--  sum(orders.items_purchased) as total_products_sold,
    sum(orders.price_usd)/count(distinct orders.order_id) as average_order_value,
    sum(orders.items_purchased)/count(distinct orders.order_id) as products_per_order,
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session

from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id

where website_sessions.created_at between '2013-11-12' and '2014-01-12'
group by 1;

-- product refund analysis
select 
	order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd as price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at
from order_items
	left join order_item_refunds
		on order_item_refunds.order_item_id = order_items.order_item_id
where order_items.order_id in(3489,32049,27061);
        
