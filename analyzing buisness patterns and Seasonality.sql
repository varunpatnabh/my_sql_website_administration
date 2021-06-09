select
	website_session_id,
    created_at,
    hour(created_at) as hr,
    weekday(created_at) as wkday, -- 00 monday
    case 
		when weekday(created_at) = 0 then "monday"
        when weekday(created_at) = 1 then "tuesday"
        else "other_day"
	end as clean_weekday,
    quarter(created_at) as qtr,
    month(created_at) as month,
    date(created_at) as week
from website_sessions
where website_session_id between 150000 and 155000;

-- assignment on patterns in year,order volume

select 
	
    year(website_sessions.created_at) as year,
    week(website_sessions.created_at) as week,
    min(date(website_sessions.created_at)) as week_start,
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at <'2013-01-01'
group by 1,2;

-- analyzing buisness patterns having avg value hour of  day and by day week basis

select
	hr,
    -- avg(website_sessions) as avg_sessions,
    round(avg(case when wkday = 0 then website_sessions else null end ),2) as monday,
    round(avg(case when wkday = 1 then website_sessions else null end ),2) as tuesday,
    round(avg(case when wkday = 2 then website_sessions else null end ),2) as wednesday,
    round(avg(case when wkday = 3 then website_sessions else null end ),2) as thursday,
    round(avg(case when wkday = 4 then website_sessions else null end ),2) as friday,
    round(avg(case when wkday = 5 then website_sessions else null end ),2) as saturday,
    round(avg(case when wkday = 6 then website_sessions else null end ),2) as sunday
    
		
   from (
   select
	date(created_at) as created_date,
    weekday(created_at) as wkday,
    hour(created_at) as hr,
    count(distinct website_session_id) as website_sessions
	
    from website_sessions
   where created_at between '2012-09-15' and '2012-11-15'
   group by 1,2,3
   ) as daily_hourly_sessions
   group by 1
   order by 1  ;
   
    