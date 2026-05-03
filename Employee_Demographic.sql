use my_first_db;
show tables;
-- 1. Filtering by age
select first_name, last_name, Age, Gender
from employee_demographics where age =30;
-- 2.  Grouping and Counting 
  select gender, count(*) as total_employees;
-- 3. Calculating average age
 select avg(age) as average_Age
 from employee_demographics
 order by average_age desc;
 -- 4. Sorting Employees
 select employee_id, first_name,last_name,Age
 from employee_demographics
 order by age desc;
      
  
      
      
  
  