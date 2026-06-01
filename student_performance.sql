
SELECT * FROM student_performance.student_database;
use student_performance;
show tables;
-- 139. Pass Rate by subjects
	select course as subject,
    sum(case when passed = 'Yes'then 1.0 else 0.0 end) * 100.0 / count(*) as 'Pass_rate'
    from student_database group by course order by pass_rate asc;
-- 140. Average score by school_type
	select school_type, avg(case when gender = 'Male' then total_score end) as avg_score_male,
    avg(case when gender ='Female' then total_score end) as avg_score_female 
	from student_database group by school_type;
-- 141. Schools with pass rate below 50%
	select school_id,count(case when passed = 'Yes'then 1.0 else 0.0 end) * 100.0 / count(*) as math_Pass_rate
    from student_database where course = 'Mathematics'group by school_id
    having math_pass_rate<50.0;
-- 142.	Top 10 schools by overall pass rate
	use student_performance;
    select school_id,count(case when passed = 'Yes' then 1.0 else 0.0 end) *100.0/ count(*) as overall_pass_rate
    from student_database group by school_id order by 2 desc limit 10; 
-- 143. Subjects where female students outperform male students
	select course as subject from student_database group by course
    having avg(case when gender = 'Female' then total_score end)> avg(case when gender = 'Male' then total_score end);
-- 144.	Attendance impact for the students
 select case when attendance_pct between 0 and 40 then '0 - 40'
 when attendance_pct between 41 and 60 then '41 - 60'
 when attendance_pct between 61 and 80 then '61 - 80'
 when attendance_pct between 81 and 100 then '81 - 100'
 else 'Unknown' end as attendance_bucket,
 avg(total_score) as avg_total_score from student_database
 group by attendance_bucket order by min(attendance_bucket);
 -- 145. students who passed all subjects in a given academic year
	select 'student-id', academic_year from student_database
    group by 'student-id',academic_year having sum(case when passed = 'No'then 1 else 0 end)= 0;
-- 146. LGA performance Ranking
	select lga, avg(total_score) as avg_score, rank() over (order by 
    avg(total_score)desc) as lga_rank
    from student_database group by lga; 
-- 147. Average score per subject comparing first and last academic 
	with yearbounds as ( select min(academic_year) as first_year, max(academic_year) as last_year
		from student_database
)
	select s.course as subject, avg(case when s.academic_year =yb.first_year then s.total_score end) as avg_score_last_year,
    (avg(case when s.academic_year =yb.first_year then s.total_score end)) as improvemet
    from student_database s
    cross join yearbounds yb
    group by s.course;
-- 148. students with 10% by average score
	with rankedstudents as (
    select student_id, avg(total_score) as avg_student_score,
    percent_rank() over(order by
    avg(total_score)asc) as score_percentile from student_database
    group by student_id
)
select student_id, avg_student_score from rankedstudents where score_percentile <=0.10 order by avg_student_score asc;
    
    

 
 
    
    

