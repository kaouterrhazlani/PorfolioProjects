use Sql_Project
-- exploration des données  
-- informations globales
--la liste des continent traités
drop table if exists #temptable
create table #temptable ( continent varchar( 100) ) 
insert into #temptable
select distinct continent from Sql_Project..CovidDeaths
where continent is not null
select * from #temptable
--la liste  des régions traités 
select distinct location from Sql_Project..CovidDeaths
where continent is null and location not in (select * from #temptable)
--la liste des pays traités ,
 select distinct location from Sql_Project..CovidDeaths
 where continent is not null

-- Les cas ,les dècés et le % des décès par covid en monde entre 05-01-2020 et 04-08-2024 
select date,sum(new_cases) as 'nombre des cas',sum(new_deaths) as 'nombre des décès', 
 	case 
	 when sum(new_cases) > 0 and sum(new_deaths) >= sum(new_cases) then 100 
	 when  sum(new_cases) > 0 and sum(new_deaths) < sum(new_cases) then round((sum(new_deaths)/sum(new_cases))*100,4) 
	 else  0
	end as '% des décès '
from Sql_Project..CovidDeaths
where continent is not null and new_cases is not null and new_deaths is not null
group by date
order by 1,2 desc
-- Les cas ,les dècés et le % des décès par covid en monde 
select sum(new_cases) as 'nombre des cas',sum(new_deaths) as 'nombre des décès', 
 	case 
	 when sum(new_cases) > 0 and sum(new_deaths) >= sum(new_cases) then 100 
	 when  sum(new_cases) > 0 and sum(new_deaths) < sum(new_cases) then round((sum(new_deaths)/sum(new_cases))*100,4) 
	 else  0
	end as '% des décès '
from Sql_Project..CovidDeaths
where continent is not null and new_cases is not null and new_deaths is not null
order by 1,2 desc

-- total des cas / décès covid dans tout le monde entre 05-01-2020 et 04-08-2024 
select continent , max(total_cases) as 'max des cas',
max(total_deaths) 'max des décès'
from Sql_Project..CovidDeaths
where continent is not null
group by continent
order by 2 desc ,3 desc

--les pays les plus touchés par covid-- 
select location,max(total_cases) as 'Le nombre Max des cas',population
from Sql_Project..CovidDeaths
where continent is not null 
group by location , population
order by 2 desc

-- Les pays ayant un nombre de décès élevé-- 
select row_number() over(order by max(total_deaths) desc ) as 'classement'
,location ,population,max(total_deaths) as 'Total Décès' 
from Sql_Project.dbo.CovidDeaths
where continent is not null
group by location,population
order by 4 desc

-- le % des décès par covid en FRANCE entre 05-01-2020 et 04-08-2024 
select location,date,population,total_cases,total_deaths, 
 	case 
	 when total_cases > 0 and total_deaths >= total_cases then 100 
	 when  total_cases > 0 and total_deaths < total_cases then round((total_deaths/total_cases)*100,4) 
	 else  0
	end as '% des décès en france',
	max(total_deaths) over () as 'total Décès de toute la période'
from Sql_Project..CovidDeaths
where continent is not null and location like 'france' 
order by 1,2 desc


-- le % des cas affectés par covid en FRANCE entre 05-01-2020 et 04-08-2024 --
select location,date,total_cases,population, 
	case 
	 when population > 0 then round((total_cases/population)*100,4)
	 else  0
	end as '% de la population affectée en france',
	max(total_cases) over () as 'total affectés de toute la période'

from Sql_Project..CovidDeaths
where continent is not null and location like 'france' 
order by 1,2 desc
 -- les continent ayant un nombre de décès élevé
 select continent,max (total_deaths) as 'Max décès'
 from Sql_Project..CovidDeaths
 where continent is not null
 group by continent
 order by 2 desc
 -- total vaccinations quotidiennes par pays entre 05-01-2020 et 04-08-2024 
 select cd.continent ,cd.location , cd.date , cd.population ,
 sum(convert(bigint, cv.total_vaccinations)) as 'total_vaccinations'
 from Sql_Project..CovidDeaths as cd
 inner join 
 Sql_Project..CovidVaccinations as cv
 on cd.location = cv.location
 and cd.date = cv.date 
 where cd.continent is not null
 group by cd.continent ,cd.location , cd.date , cd.population 
 order by 2,3
 --Cumule des  nouvelles vaccinations quotidiennes  
 --Le pourcentage quotidien  
 --par pays entre 05-01-2020 et 04-08-2024  
 with CTE_CumuleVaccination(continent,location,date,population,newVaccinations,CumuleVaccination) 
 as
 (select 
 cd.continent, cd.location , cd.date , cd.population , cv.new_vaccinations as 'new vaccinations',
 sum(cast(cv.new_vaccinations as bigint))
 over ( partition by cd.location order by cd.date) as 'Cumule Vaccination' 
 from Sql_Project..CovidDeaths as cd
 inner join 
 Sql_Project..CovidVaccinations as cv
 on cd.location = cv.location
 and cd.date = cv.date
 where cd.continent is not null  --and cv.new_vaccinations is not null 
 and cd.location like 'morocco'
 group by cd.continent, cd.location , cd.date , cd.population , cv.new_vaccinations
 --order 3,6
 )
 select *, round((CumuleVaccination/population)*100,4) as '% des Vaccinations' 
 from CTE_CumuleVaccination
 order by 2,3

 -- creation des vues/view
 --creation view pour stocker les resultats de la requete
create view lesPaysLesPlusTouches as 
select location,max(total_cases) as 'Le nombre Max des cas',population
from Sql_Project..CovidDeaths
where continent is not null 
group by location , population

select * from lesPaysLesPlusTouches

create view LeCumuleDesVaccinationParPopulation as
select 
 cd.continent, cd.location , cd.date , cd.population , cv.new_vaccinations as 'new vaccinations',
 sum(cast(cv.new_vaccinations as bigint))
 over ( partition by cd.location order by cd.date) as 'Cumule Vaccination' 
 from Sql_Project..CovidDeaths as cd
 inner join 
 Sql_Project..CovidVaccinations as cv
 on cd.location = cv.location
 and cd.date = cv.date
 where cd.continent is not null  --and cv.new_vaccinations is not null 
 and cd.location like 'morocco'
 group by cd.continent, cd.location , cd.date , cd.population , cv.new_vaccinations
 --order 3,6

 select * from LeCumuleDesVaccinationParPopulation