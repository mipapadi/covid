use Covid


-- Checking our tables
select * from Covid..CovidDeaths 
select * from Covid..CovidVaccinations

select * from Covid..CovidDeaths order by 3,4


-- Select data that we are going to be using 
select location,date, total_cases, new_cases, total_deaths, population
from Covid..CovidDeaths
order by 1,2


-- Looking at total_cases VS total_deaths
-- Shows the chance of dying from covid on Greece
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from Covid..CovidDeaths
where location like '%Gre%'
order by 1,2


-- Looking for total_cases vs population
-- Shows the percentage of population got Covid on Greece
select location, date, population,total_cases, (total_cases/population)*100 as population_infected_percentage
from Covid..CovidDeaths
where location='Greece'
order by 1,2


-- Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as highest_infection_point, max(total_cases/population)*100 as max_population_infected_percentage	
from Covid..CovidDeaths
group by location, population
order by 4 desc


-- Showing countries with highest death point over population
select location, max(cast(total_deaths as int)) as highest_death_point
from Covid..CovidDeaths
where continent is not null
group by location
order by 2 desc


-- Showing continents with highest death point over population
select continent, max(cast(total_deaths as int)) as highest_death_point
from Covid..CovidDeaths
where continent is not null
group by continent
order by 2 desc


-- Searching for global numbers
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as world_death_percentage
from Covid..CovidDeaths
where continent is not null 


-- Looking at population vs vaccinations
-- Shows number of population, that has recieved at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as ongoing_people_vaccinated
from Covid..CovidDeaths as dea
join Covid..CovidVaccinations as vac 
on dea.location=vac.location and dea.date=vac.date
where dea.location = 'Greece'
order by 2,3


-- Using CTE to perform calculation on partition by in previous query
-- Here we notice a problem with dataset. It is impossible to have total_vaccinations_per_hundred and people_fully_vaccinated_per_hundred over 100. 
-- I guess that this happens because under the summary of daily vaccinations there are different cases. About people who are in different vaccination stage.
-- But i want to keep this just for educational reasons
with pop_vac (continent, location, date, population, new_vaccinations, ongoing_people_vaccinated) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as ongoing_people_vaccinated
from Covid..CovidDeaths as dea
join Covid..CovidVaccinations as vac 
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
)
select *, (ongoing_people_vaccinated/population)*100 as ong_ppl_vac_percentage
from pop_vac


-- Using temp table method to perform calculation on partition by in previous query
drop table if exists #PercPopVacc

create table #PercPopVacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_Vaccinations numeric,
Ongoing_People_Vaccinated numeric
)

insert into #PercPopVacc
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as ongoing_people_vaccinated
from Covid..CovidDeaths as dea
join Covid..CovidVaccinations as vac 
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null

select *, (ongoing_people_vaccinated/population)*100 as ong_ppl_vac_percentage
from #PercPopVacc


-- Creating View to store data for later visualizations
CREATE VIEW VaccinatedPopulationPercentage as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as ongoing_people_vaccinated
from Covid..CovidDeaths as dea
join Covid..CovidVaccinations as vac 
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null