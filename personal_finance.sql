SELECT * FROM personal_finance.personal_finance;
show tables;
-- 13.Net position per user(Income  - Expense)
select user_id,
			sum(case when transaction_type = 'income' then amount_ngn else 0 end)  -
            sum(case when transaction_type = 'Expense' then amount_ngn else 0 end) as net_position
from personal_finance group by user_id;
-- 14. Average Monthly spending Category
	select category, avg(amount_ngn) as avg_monthly_spend
    from personal_finance where transaction_type = 'Expense' group by category;
-- 15. Users with a savings rate above 20%
	select user_id from personal_finance group by user_id
    having  (sum(case when category = 'savings_goal_met' then amount_ngn else 0 end)/
		   nullif(sum(case when transaction_type ='income' then amount_ngn else 0 end), 0))>0.20;
-- 16.	Top spending category per month
with monthlyCategorySpend as (
	select month, category, sum(amount_ngn) as total_spent
    from personal_finance where transaction_type = 'Expense' group by month, category
),
RankedSpend as (
	select *, rank() over(partition by month order by total_spent desc) as rnk
    from MonthlyCategorySpend
)
select*from rankedSpend where rnk = 1;
-- 17. Bank  popularity
	select bank, count(*) as tnx_count, sum(amount_ngn) as total_volume
    from personal_finance group by bank;
-- 18. Monthly Net Saving Trend
select month, year,
	sum(case when transaction_type = 'income' then amount_ngn else 0 end) -
    sum(case when transaction_type = 'Expense' then amount_ngn else 0 end) as net_savings
from personal_finance group by year, month order by year,month;
-- 19. Users who have never saved 
select user_id  from personal_finance group by user_id
having sum(case when category = 'savings_goal_met' then 1 else 0 end) = 0;
-- 20. Cumulative Spending per user
select user_id, transaction_date, amount_ngn,
	sum(amount_ngn)over (partition by user_id order by transaction_date) as cumulative_spend
from personal_finance where transaction_type = 'Expense';
-- 21. Month with Highest Average Expense 
select month, avg(amount_ngn) as avg_exp
from personal_finance where transaction_type = 'Expense'
group by month order by avg_exp desc limit 1;
-- 22. Common table Expression
With UserSpending as (
	select  user_id, sum(amount_ngn) as total_spent
    from personal_finance where transaction_type = 'Expense' group by user_id
),
percentile as (
select *, percent_rank() over(order by total_spent desc) as p_rank
from UserSpending 
)
select * from percentile  where p_rank <=0.10;