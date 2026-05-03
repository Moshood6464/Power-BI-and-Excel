use my_first_db;
show tables;
select * from employee_demographics;
-- 1. Filtering by Age
select first_Name, last_Name, Age, gender
from employee_demographics where Age=30;
-- 2. Grouping  and Counting 
 select gender, count(*) as Total_employees
 from employee_demographics group by Gender;
 


