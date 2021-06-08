select 
	utm_content,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.website_session_id) as orders,
    
    count(distinct orders.website_session_id)/count(distinct website_sessions.website_session_id) as session_to_order_conversion_rate
    
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at between '2014-01-01' and '2014-02-01'
group by 1
order by sessions desc;

select
	-- yearweek(created_at) as yrwk,
    
	min(date(website_sessions.created_at)) as week_start_date,
    count(distinct website_session_id) as totals,
    count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch,
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch

from website_sessions
where created_at < '2012-11-29'
	and created_at > '2012-08-22'
 and utm_campaign = 'nonbrand'
group by yearweek(created_at);

-- assignment on comparing channel characteristics

select 
	utm_source,
    count(distinct website_session_id) as sessions,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions,
    count(distinct case when device_type = 'mobile' then website_session_id else null end)/count(distinct website_session_id) as mob_prct
from website_sessions
where utm_source in ('bsearch' ,'gsearch')
	and created_at between '2012-08-22' and '2012-11-30'
    and utm_campaign = 'nonbrand'
group by 1;

-- cross channel bid optimization

select
	device_type,
    utm_source,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
    
from website_sessions
left join orders
		on orders.website_session_id = website_sessions.website_session_id
where utm_campaign = 'nonbrand'
	and website_sessions.created_at between '2012-08-22' and '2012-09-18'
group by 1,2;

-- channel portfolio trends

select 
	min(date(created_at)) as week_start_date,
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end)
    as g_desk_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)
    as b_desk_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)/
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end)
    as b_part_of_g_desktop,
    count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end)
    as g_desk_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end)
    as b_desk_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end)/
    count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end)
    as b_part_of_g_mob
    
    
from website_sessions
where created_at between '2012-11-04' and '2012-12-22'
and utm_campaign = 'nonbrand'
group by yearweek(created_at);

-- free trafffic analysis

select 
	
	case
		when http_referer is null then 'direct_type_in'
		when http_referer = 'https://www.gsearch.com' and utm_source  is null then 'gsearch_organic'
		when http_referer = 'https://www.bsearch.com' and utm_source  is null then 'bsearch_organic'
		else 'other'
	end as cases,
    count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000
-- and utm_source is null
group by 1
order by 2 desc
;

-- assignnment analyzing Direct traffic
    

select 
	website_session_id,
    created_at,
	case
		when utm_source is null and http_referer in ('https://www.gsearch.com' , 'https://www.bsearch.com') then 'organic_search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
	end as channel_group
    -- utm_source,
    -- utm_campaign,
    -- http_referer
from  website_sessions
where created_at < '2012-12-23';


select 
	year(created_at) as yr,
    month(created_at) as mo,
    count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as nonbrand,
    count(distinct case when channel_group = 'paid_brand' then website_session_id else null end) as brand,
    count(distinct case when channel_group = 'paid_brand' then website_session_id else null end)/
		count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as brand_pct_of_nonbrand,
	count(distinct case when channel_group = 'direct_type_in' then website_session_id else null end) as direct,
    count(distinct case when channel_group = 'direct_type_in' then website_session_id else null end)/
		count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as direct_pct_of_nonbrand,
	count(distinct case when channel_group = 'organic_search' then website_session_id else null end) as organic,
	count(distinct case when channel_group = 'organic_search' then website_session_id else null end)/
		count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as organic_pct_of_nonbrand

from (
select 
	website_session_id,
    created_at,
	case
		when utm_source is null and http_referer in ('https://www.gsearch.com' , 'https://www.bsearch.com') then 'organic_search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
	end as channel_group
    -- utm_source,
    -- utm_campaign,
    -- http_referer
from  website_sessions
where created_at < '2012-12-23'
) as session_w_channel_group
group by
	year(created_at),
    month(created_at)
order by mo;



