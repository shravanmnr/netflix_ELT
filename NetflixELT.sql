use NetflixELT

select * from netflix_raw order by title
-- HANDELING FOREIGN CHARCTERS


create TABLE [dbo].[netflix_raw](
    [show_id] [varchar](10) primary key,
    [type] [varchar](10) NULL,
    [title] [nvarchar](200) NULL,
    [director] [varchar](250) NULL,
    [cast] [varchar](800) NULL,
    [country] [varchar](150) NULL,
    [date_added] [varchar](20) NULL,
    [release_year] [int] NULL,
    [rating] [varchar](10) NULL,
    [duration] [varchar](20) NULL,
    [listed_in] [varchar](100) NULL,
    [description] [varchar](500) NULL
)
GO


SELECT * FROM netflix_raw where show_id = 's5023'
drop table netflix_raw

select count(*) from netflix_raw where rn = 1


-- REMOVE DUPLICATES
select * from netflix_raw
where concat(upper(title),type) in(
	select concat(upper(title),type)
	from netflix_raw
	group by upper(title), type
	having COUNT(*)>1  
)order by title


with cte as(select *,ROW_NUMBER()over (partition by title , type order by show_id) as rn
from netflix_raw)
select * from cte
where rn=1

--new table for Listed_in, directors, country,cast


select show_id , trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in,',')

Select * from netflix_director
Select * from netflix_country
Select * from netflix_cast
Select * from netflix_genre

with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_raw
)
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description
into netflix
from cte 
where rn =1

select * from netflix

select * from netflix_raw

--DATA ANALYSIS PART

--  for each director count the no of movies and tv shows created by them in separate columns for directors who have created tv shows and movies both
 


select nd.director 
,COUNT(distinct case when n.type='Movie' then n.show_id end) as no_of_movies
,COUNT(distinct case when n.type='TV Show' then n.show_id end) as no_of_tvshow
from netflix n
inner join netflix_director nd on n.show_id=nd.show_id
group by nd.director
having COUNT(distinct n.type)>1


--Which country has higest number of comedy movies

select top 1  nc.country , COUNT(distinct ng.show_id ) as no_of_movies
from netflix_genre ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.genre='Comedies' and n.type='Movie'
group by  nc.country
order by no_of_movies desc

-- for each year (as per date added to netflix), which director has maximum number of movies released
with cte as (
select nd.director,YEAR(date_added) as date_year,count(n.show_id) as no_of_movies
from netflix n
inner join netflix_director nd on n.show_id=nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_year order by no_of_movies desc, director) as rn
from cte
)
select * from cte2 where rn=1

-- what is average duration of movies in each genre
select ng.genre , avg(cast(REPLACE(duration,' min','') AS int)) as avg_duration
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
where type='Movie'
group by ng.genre

--5  find the list of directors who have created horror and comedy movies both. display director names along with number of comedy and horror movies directed by them
 
select nd.director
, count(distinct case when ng.genre='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.genre='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
inner join netflix_director nd on n.show_id=nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.genre)=2;

select * from netflix_genre where show_id in 
(select show_id from netflix_director where director='Steve Brill')
order by genre