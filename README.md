# my_sql_website_administration
 #sql_assignments
 #date 23-05-2021

 use mavenfuzzyfactory;

select 
	website_sessions.utm_content,
    count(distinct website_sessions.website_Session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_Session_id) as convt_ratio
from website_sessions
	left join orders
    on orders.website_session_id = website_sessions.website_session_id
where website_sessions.website_session_id between 1000 and 2000 -- arbitraray
group by
	utm_content
order by sessions desc;

-- Assignment
select 
	utm_source,
    utm_campaign,
    http_referer,
    count(distinct website_session_id) as sessions
    
from website_sessions
where created_at < '2012-04-12'
group by utm_source,
    utm_campaign,
    http_referer
order by 4 desc;


-- traffic conversion rate

select * from orders;
select 
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
left join orders
	on orders.website_session_id = website_sessions.website_session_id
    where website_sessions.created_at < '2012-04-14' -- not orders.created_at
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
        
    ;
    select 
	count(distinct website_sessions.website_session_id) as sessions
    from website_sessions
    where created_at < '2012-04-14'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';
-- bid optimization and trend analysis

select
	year(created_at),
    week(created_at),
    min(date(created_at)) as week_start, -- for cleaner look and seeing starting date
    count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000
group by 1,2;

-- case pivoting

select
	primary_product_id,
   -- order_id,
   -- items_purchased,
    count(case when items_purchased = 1 then order_id else null end) as single_order,
    count(case when items_purchased = 2 then order_id else null end) as double_order
from orders
where order_id between 31000 and 32000
group by 1
order by 1;

-- assignment on traffic source trending
select 
	min(date(created_at)) as week_start_date,
    count(website_session_id) as sessions
from website_sessions
where created_at < '2012-05-10'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by -- year(created_at),
		week(created_at);
        
-- assignment on traffic source bid optimization

select 
	website_sessions.device_type,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(orders.order_id)/count(website_sessions.website_session_id) as session_to_order_cnv_rate
from website_sessions
left join orders
	on orders.website_session_id=website_sessions.website_session_id
where website_sessions.created_at < '2012-05-11'
and utm_source = 'gsearch'

and utm_campaign = 'nonbrand'
group by 1
-- desktop perform better than mobile
;



-- assignment on traffic source segment trending

select 
	min(date(created_at)) as week_start_date,
    count(distinct case when device_type = 'desktop' then website_session_id else null end) as dtp_session,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) as mob_session
    from website_sessions
where created_at < '2012-06-09'
and created_at > '2012-04-15'
and utm_campaign = 'nonbrand'
and utm_source = 'gsearch'
group by week(created_at);

--
-- top website pages
select
	pageview_url,
    count(distinct website_pageview_id) as pvs
from website_pageviews
where website_pageview_id < 1000
group by 1
order by 2 desc;

-- creating temp table for top entry pages
create temporary table frst_pvw
select 
	website_session_id,
    min(website_pageview_id) as min_pvw_id -- on min pageview id with session id i.e the 8th session id has the 12th as its firt pageview id 
from website_pageviews
where website_pageview_id < '1000'
group by website_session_id;

select * from frst_pvw;

select 
	-- frst_pvw.website_session_id,
    website_pageviews.pageview_url as landing_page, -- entry pages
	count(distinct frst_pvw.website_session_id) as hitting_lander
from frst_pvw
	left join website_pageviews
		on frst_pvw.min_pvw_id = website_pageviews.website_pageview_id;
        

-- assignment on finding top website pages

select
	pageview_url,
    count(distinct website_session_id) as sessions
from website_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc;

-- assignment on finding top entry pages using temp table

select
	pageview_url,
    count(distinct website_session_id) as sessions
from website_pageviews
where created_at < '2012-06-12'
-- and  pageview_url in ( '/home', '/products','/the-original-mr-fuzzy')
;

-- by other way

create temporary table first_pv_per_session
select
	website_session_id,
    min(website_pageview_id) as first_pv
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id;

select 
	website_pageviews.pageview_url as landing_page_url,
    count(distinct first_pv_per_session.website_session_id) as session_hitting_page
from first_pv_per_session
	left join website_pageviews
    on first_pv_per_session.first_pv = website_pageviews.website_session_id;

# date 24-05-2021
-- analyzing bounce rates and landing page test

-- buisness context : we want to see landing page performance for a certain time period

-- step 1 : find the first_website_pageview_id for relevant sessions
-- s2 : identify the landing page of each session
-- s3:  counting pageviews for each sessions, to identify " bounces"
-- s4 : summmarizing total sessions and bounced sessions, by lannding page(lp)

-- finding the min website pageview id associated with each session we care about

select 
		website_pageviews.website_session_id,
        min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions
    on website_sessions.website_session_id = website_pageviews.website_session_id
    and website_sessions.created_At between '2014-01-01' and '2014-02-01'
group by
	website_pageviews.website_session_id;
    
    -- same query as above , but this time we are storing the data set in a temp table
    
    create temporary table first_pvw_demo
    select 
		website_pageviews.website_session_id,
        min(website_pageviews.website_pageview_id) as min_pvw_id
	from website_pageviews
		inner join website_sessions
			on website_sessions.website_session_id = website_pageviews.website_session_id
	and website_sessions.created_At between '2014-01-01' and '2014-02-01'
    group by
    website_pageviews.website_session_id;
    
    -- next we bring in the landing page name to each session
    
    create temporary table sessions_w_landing_page_demo
    select 	
		first_pvw_demo.website_session_id,
        website_pageviews.pageview_url as landing_page
	from first_pvw_demo
    left join website_pageviews
		on website_pageviews.website_pageview_id = first_pvw_demo.min_pvw_id -- website pvw is the main landing page view
    ;
    
    -- next we make a table include a count of pageviews per sessions
    
    -- first we see the sessions, then we will limit to bounc3ed sessions and create a temp table
    
    create temporary table bounced_session_only
    select 
		sessions_w_landing_page_demo.website_session_id,
        sessions_w_landing_page_demo.landing_page,
        count(website_pageviews.website_pageview_id) as count_of_pages_viewed
	from sessions_w_landing_page_demo
    left join website_pageviews
		on website_pageviews.website_session_id = sessions_w_landing_page_demo.website_session_id
	
    group by
		sessions_w_landing_page_demo.website_session_id,
        sessions_w_landing_page_demo.landing_page
        
	having 
		count(website_pageviews.website_pageview_id) = 1;
        
	-- we will do this, then sumarize with a count after:
    
    select
		sessions_w_landing_page_demo.landing_page,
        sessions_w_landing_page_demo.website_session_id,
        bounced_session_only.website_session_id as bounced_website_session_id
	from sessions_w_landing_page_demo
		left join bounced_session_only
			on sessions_w_landing_page_demo.website_session_id = bounced_session_only.website_session_id
	order by sessions_w_landing_page_demo.website_session_id;
    
    -- final output
    -- we will use the same query we previously ran, and run a count of records
    -- we will group by landing page, and then we will add a bounce rate column
    
    select 
		sessions_w_landing_page_demo.landing_page,
        count(distinct sessions_w_landing_page_demo.website_session_id) as sessions,
        count(distinct bounced_session_only.website_session_id ) as bounced_sessions,
		count(distinct bounced_session_only.website_session_id )/count(distinct sessions_w_landing_page_demo.website_session_id) as bounced_rate
    from sessions_w_landing_page_demo
		left join bounced_session_only
			on sessions_w_landing_page_demo.website_session_id = bounced_session_only.website_session_id
	group by 1
    order by 4;
    
    -- assignment on calculating the bounce rates
    
    -- s1 : finding the first website_pageview_id for relevant sessions
    -- s2 : identyifying the landing page of each session
    -- s3 : counting pageviews for each session, to identify " bounces"
    -- s4 : summarizing by counting total sessions and bounced sessions
    
    create temporary table first_pageviews
    select 
		website_session_id,
        min(website_pageview_id) as min_pageview_id
	from website_pageviews
    where created_at < '2012-06-14'
    group by 1;
    
    -- next we will bring in the landing page , like last time but restrict to home only
    -- this is redundant in this case , since all is to the home page
    
    create temporary table sessions_w_home_landing_page
    select 
		first_pageviews.website_session_id,
        website_pageviews.pageview_url as landing_page
        from first_pageviews
			left join website_pageviews
				on website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
		where website_pageviews.pageview_url = '/home';
        
        -- then a table to have a count of pageviews per session
        -- then limit it to just bounced sesssions
	
    create temporary table bounced_sessions
	select
		sessions_w_home_landing_page.website_session_id,
        sessions_w_home_landing_page.landing_page,
        count(website_pageviews.website_pageview_id) as count_of_pages_viewed
        
	from sessions_w_home_landing_page
    left join website_pageviews
		on website_pageviews.website_session_id = sessions_w_home_landing_page.website_session_id
	group by 1,2
    
     having count(website_pageviews.website_pageview_id) = 1;
     select * from bounced_sessions;
     
     -- we will do this first just to show whats in this query , then we will count them after
     select
		count(distinct sessions_w_home_landing_page.website_session_id) as sessions,
        count(distinct bounced_sessions.website_session_id) as bounced_session,
        count(distinct bounced_sessions.website_session_id)/count(distinct sessions_w_home_landing_page.website_session_id) as bounce_rate
	from sessions_w_home_landing_page
		left join bounced_sessions
			on sessions_w_home_landing_page.website_session_id = bounced_sessions.website_session_id
		order by 1;
        
        -- assignment on analyzing landing page test
        -- s0 : find out when the new page/lander launched
        -- s1 : finding the first website_pageview_id for relevant sessions
        -- s2 : identyifying the landing page of each session
        -- s3 : counting pageviews for each session, to identify " bounces"
        -- s4 : summarazing total sessions and bounced sessions , by landing page
        
        select 
			min(created_at) as first_created_at,
            min(website_pageview_id) as first_pageview_id
		from website_pageviews
        where pageview_url = '/lander-1'
			and created_at is not null;
            
		create temporary table first_test_pageviews
        select 
			website_pageviews.website_session_id,
            min(website_pageviews.website_pageview_id) as min_pageview_id
		from website_pageviews
			inner join website_sessions
				on website_sessions.website_session_id = website_pageviews.website_session_id
                and website_sessions.created_at < '2012-07-28' -- prescribed by the assignment
                and website_pageviews.website_pageview_id > 23504 -- the min_pageview_id we found 
                and utm_source = 'gsearch'
                and utm_campaign = 'nonbrand'
		group by website_pageviews.website_session_id;
        
        -- now we bring in the landing page to each session, like last time,but restricting to home or lander-1 this time
        
        create temporary table nonbrand_test_sessions_w_landing_page
         select 
			first_test_pageviews.website_session_id,
            website_pageviews.pageview_url as landing_page
		from first_test_pageviews
			left join website_pageviews
				on website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
		where website_pageviews.pageview_url in 
        ('/home','/lander-1');
        
        -- then a table to have count of pageviews per session
        -- then limit it to just bounced sessions
        
        create temporary table nonbrand_test_bounced_sessions
        select 
			nonbrand_test_sessions_w_landing_page.website_session_id,
            nonbrand_test_sessions_w_landing_page.landing_page,
            count(website_pageviews.website_pageview_id) as count_of_pages_viewed
		from nonbrand_test_sessions_w_landing_page
        left join website_pageviews
			on website_pageviews.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
		group by 1,2
        having 
			count(website_pageviews.website_pageview_id) = 1;
            
		-- 
        select 
			nonbrand_test_sessions_w_landing_page.landing_page,
            count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) as sessions,
            
            count(distinct nonbrand_test_bounced_sessions.website_session_id) as bounced_session,
			count(distinct nonbrand_test_bounced_sessions.website_session_id)/count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) as bounce_rate
        from nonbrand_test_sessions_w_landing_page
			left join nonbrand_test_bounced_sessions
				on nonbrand_test_sessions_w_landing_page.website_session_id = nonbrand_test_bounced_sessions.website_session_id
		group by 1
        order by 1;
        
-- assignment on landing page trend analysis

-- s1: finding the first website_pageview_id for relevant sessions
-- s2: identyfying the landing page of each session
-- s3: counting pageviews for each session, to identify "bounces"
-- s4: summarizing by wweek (bounce rate, session to each lander)

create temporary table sessions_w_min_pv_id_and_view_count
select
	website_sessions.website_session_id,
    min(website_pageviews.website_pageview_id) as first_pageview_id,
    count(website_pageviews.website_pageview_id) as count_pageviews
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-01'
	and website_sessions.created_at < '2012-08-31'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'

group by 1;

create temporary table sessions_w_counts_lander_and_created_at
select 
	sessions_w_min_pv_id_and_view_count.website_session_id,
    sessions_w_min_pv_id_and_view_count.first_pageview_id,
    sessions_w_min_pv_id_and_view_count.count_pageviews,
    website_pageviews.pageview_url as landing_page,
    website_pageviews.created_at as sessions_created_at
from sessions_w_min_pv_id_and_view_count
	left join website_pageviews
		on sessions_w_min_pv_id_and_view_count.first_pageview_id = website_pageviews.website_pageview_id
;
-- result weekely arranged
select 
	-- yearweek(sessions_created_at) as year_week,
    min(date(sessions_created_at)) as week_start_date,
    -- count(distinct website_session_id) as total_sessions,
    -- count(distinct case when count_pageviews = 1 then website_session_id else null end) as bounced_session, 
	count(distinct case when count_pageviews = 1 then website_session_id else null end)*1.0/count(distinct website_session_id) as bounce_rate,
    count(distinct case when landing_page = '/home' then website_session_id else null end) as home_sessions,
    count(distinct case when landing_page = '/lander-1' then website_session_id else null end) as lander_session
    
from sessions_w_counts_lander_and_created_at
group by yearweek(sessions_created_at);

-- Analyzing and testing conversion funnels

-- buisness context
	-- we want to build a mini conversion funnel, from /lander-2 to /cart
    -- we want to know how many people reach each step, and also drop off rates
    -- for simplicity of the demo , we are looking at /laner-2 traffic only
    -- for simplicity of the demo, we are looking at customer who like mr fuzzy only
    
    
-- s1 : select all pageviews for relevant sessions
-- s2 : identify each relevant pageviews as the specific funnel step
-- s3 : create the session-level conversion funnel view
-- s4 : aggregate the data to assess funnel performance

-- first i will show you all of the pageviews we care about
-- then, i will remove the comments from my flag columns one by one

select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at
    , case when pageview_url = '/products' then 1 else 0 end as products_page
    , case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page
    , case when pageview_url ='/cart' then 1 else 0 end as cart_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at between '2014-01-01' and '2014-02-01'
	and website_pageviews.pageview_url in ('/lander-2' , '/products','/the-original-mr-fuzzy','/cart')
    order by
		1,3;
        
-- next we will put the previous query inside a subquery(similar to temporary tables)
-- we will group by website_session_id, and take the max() of each of the flags
-- this max() becomes a made_it flag for that session, to show the session made it there

select	
	website_session_id,
    max(products_page) as product_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) as cart_made_it
    
from( 
select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page
    , case when pageview_url ='/cart' then 1 else 0 end as cart_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at between '2014-01-01' and '2014-02-01'
	and website_pageviews.pageview_url in ('/lander-2' , '/products','/the-original-mr-fuzzy','/cart')
order by
	website_sessions.website_session_id,
    website_pageviews.created_at
) as pageview_level

group by website_session_id;


