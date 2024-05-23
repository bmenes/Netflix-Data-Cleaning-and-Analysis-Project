

--handling foreign characters

--remove duplicates

select * from netflix_table
where CONCAT(upper(title),type) in(
select CONCAT(upper(title),type)
from netflix_table
group by upper(title),type
having COUNT(*)>1
)
order by title 



with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_table
)
select show_id,type,title,CAST(date_added as date) as date_added,release_year,
rating,case when duration is null then rating else duration end as duration,description
into netflix
from cte
where rn=1

select * from netflix



--create director table
select show_id,TRIM(value) as director
into netflix_directors
from netflix_table
cross apply string_split(director,',') 



--create country table
select show_id,TRIM(value) as country
into netflix_country
from netflix_table
cross apply string_split(country,',') 

--create cast table
select show_id,TRIM(value) as cast
into netflix_cast
from netflix_table
cross apply string_split(cast,',') 

--create listed_in table
select show_id,TRIM(value) as listed_in
into netflix_listed_in
from netflix_table
cross apply string_split(listed_in,',') 


select * from netflix_directors
select * from netflix_country
select * from netflix_cast
select * from netflix_listed_in

--new table for listed in , director,country,cast 

select * from netflix_table


--populate missing values in country,duration columns

insert into netflix_country
select  show_id,m.country 
from netflix_table nr
inner join (
select director,country
from  netflix_country nc
inner join netflix_directors nd on nc.show_id=nd.show_id
group by director,country
) m on nr.director=m.director
where nr.country is null

-----------




--netflix data analysis

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

select nd.director,
COUNT(distinct case when n.type='Movie' then n.show_id end) as movie_count
,COUNT(distinct case when n.type='TV Show' then n.show_id end) as tvshow_count
from netflix n
inner join netflix_directors nd 
on nd.show_id=n.show_id
group by nd.director
having COUNT( distinct n.type) > 1


--2 which country has highest number of comedy movies 

 select top 1 nc.country,count(*) as count_comedies
 from netflix n
 inner join netflix_listed_in nl 
 on n.show_id=nl.show_id
 inner join netflix_country nc
 on n.show_id=nc.show_id
 where nl.listed_in='Comedies' and n.type='Movie'
 group by nc.country
 order by count_comedies desc


 --3 for each year (as per date added to netflix), which director has maximum number of movies released


 WITH cte_count AS (
  SELECT 
    YEAR(date_added) AS date_year,
    nd.director,
    COUNT(n.show_id) AS count_of_movies
  FROM netflix n
  INNER JOIN netflix_directors nd
  ON n.show_id = nd.show_id
  WHERE n.type = 'Movie'
  GROUP BY nd.director, YEAR(date_added)
),
cte_rank AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY date_year ORDER BY count_of_movies DESC) AS rank_of_year
  FROM cte_count
)

select * from cte_rank
where rank_of_year=1


--4 what is average duration of movies in each genre
SELECT nl.listed_in, AVG(CAST(SUBSTRING(nt.duration, 1, CHARINDEX(' ', nt.duration) - 1) AS int)) AS duration_avg
FROM netflix_table nt
INNER JOIN netflix_listed_in nl ON nt.show_id = nl.show_id
GROUP BY nl.listed_in
order by 2 desc


--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 


select nd.director,
count(distinct case when nl.listed_in='Comedies'  then nt.show_id end) as Comedies_Count,
count(distinct case when nl.listed_in='Horror Movies'  then nt.show_id end) as Horor_Count
from netflix_table nt
inner join netflix_directors nd
on nd.show_id=nt.show_id
inner join netflix_listed_in nl
on nt.show_id=nl.show_id
where nt.type='Movie'  and nl.listed_in in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct nl.listed_in)=2;


select nd.director
, count(distinct case when ng.listed_in='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.listed_in='Horror Movies' then n.show_id end) as no_of_horror
from netflix_table n
inner join netflix_listed_in ng on n.show_id=ng.show_id
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie' and ng.listed_in in ('Comedies','Horror Movies') 
group by nd.director
having COUNT(distinct ng.listed_in)=2;

select * from netflix_listed_in where show_id in 
(select show_id from netflix_directors where director='Steve Brill')
order by listed_in



