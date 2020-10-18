with ranked_visits as
(
	select user_id, dt, extract(month from dt) as mnt, row_number() over(partition by user_id order by dt) as dt_rank
	from public.user_log
),
cohorts as
(
	select mnt, user_id 
	from  ranked_visits 
	where dt_rank = 1
),
user_activity as 
(
	select user_id, extract(month from dt) as mnt
	from public.user_log
	group by 1,2
),
cross_join as 
(
	select user_id, mnt 
	from (select user_id from public.user_log group by 1) as u, (select extract(month from dt) as mnt from public.user_log group by 1) as m
),
working_set as 
(
	select 
		c_j.user_id
		, c_j.mnt
		, case when u_a.user_id is not null then 1 else 0 end as is_active
		, c.user_id as cohort_user_id
		, c.mnt as cohort
	from cross_join c_j
		 left join user_activity u_a on (c_j.user_id = u_a.user_id and c_j.mnt = u_a.mnt)
		 left join cohorts c on c_j.user_id = c.user_id
	where c_j.mnt >= c.mnt
	order by 1,2
)
select 
	cohort
	, mnt
	, sum(is_active) as total_monthly_active
	, count(user_id) as total_cohort_users
	, sum(is_active) / count(user_id)::float as retention_rate
from working_set
group by 1, 2
order by 1, 2
