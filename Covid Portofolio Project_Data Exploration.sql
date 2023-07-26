SELECT *
FROM PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2
	
--Select the data that we are going to using
SELECT location, date,total_cases, new_cases, total_deaths, population
FROM PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date ASC

--Total cases vs Total deaths in Indonesia
ALTER TABLE PortofolioCovidproject..coviddeaths
ALTER COLUMN total_cases INT

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From PortofolioCovidProject..coviddeaths
WHERE  location = 'Indonesia'
ORDER BY location, date

--Total cases vs Population
Select Location, date, population, total_cases, (total_cases/population)*100 as PopulationInfected_Percentage
From PortofolioCovidProject..coviddeaths
--WHERE  location = 'Indonesia'
ORDER BY location, date;

--Countries with the highest Infection Rate compared to Population
Select Location, population, MAX(total_cases)as HighestInfectionRate, MAX((total_cases/population))*100 as PopulationInfected_Percentage
From PortofolioCovidProject..coviddeaths
GROUP BY population, location
ORDER BY PopulationInfected_Percentage DESC;


ALTER TABLE PortofolioCovidproject..coviddeaths
ALTER COLUMN total_deaths INT

--Countries with the highest Death Count per Population
--Continent
Select continent, MAX (total_deaths) TotalDeathsCounts
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathsCounts DESC

--Location
Select location, MAX (total_deaths) TotalDeathsCounts
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathsCounts DESC


ALTER TABLE PortofolioCovidproject..coviddeaths
ALTER COLUMN new_deaths INT

ALTER TABLE PortofolioCovidproject..coviddeaths
ALTER COLUMN new_cases INT

--Global Numbers
--Show global numbers of new cases an new deaths each date globally
SELECT date, SUM(new_cases) AS Total_cases, SUM(new_deaths) AS Total_deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(new_deaths)*100.0/SUM(new_cases)
END AS Deaths_Percentage
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


--Show numbers of global daily new cases/deaths
SELECT date, location, SUM(new_cases) AS Daily_cases, SUM(new_deaths) AS Total_deaths, SUM(total_cases) AS Globaltotalcases
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY date, location
ORDER BY date

--Show numbers of daily new cases/deaths with specific location
SELECT date, location, SUM(new_cases) AS Daily_cases, SUM(new_deaths) AS Total_deaths, SUM(total_cases) AS Globaltotalcases
From PortofolioCovidProject..coviddeaths
WHERE location = 'Indonesia'
AND continent IS NOT NULL
GROUP BY date, location
ORDER BY 1, 2


--Show total number of new cases and new deaths
SELECT SUM(new_cases) AS Total_cases, SUM(new_deaths) AS Total_deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(new_deaths)*100.0/SUM(new_cases)
END AS Deaths_Percentage
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Join covid deaths table and covid vaccination table
SELECT *
FROM PortofolioCovidProject..coviddeaths AS c_death
JOIN PortofolioCovidProject..covidvaccination AS c_vaccination
ON c_death.location = c_vaccination.location
AND c_death.date = c_vaccination.date

--Looking at Total Population vs Vaccination
SELECT c_death.continent, c_death.location, c_death.date, c_death.population, c_vaccination.new_vaccinations
, SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY c_death.location ORDER BY c_death.location, c_death.date) AS RollingPeopleVaccinated
FROM PortofolioCovidProject..coviddeaths AS c_death
JOIN PortofolioCovidProject..covidvaccination AS c_vaccination
ON c_death.location = c_vaccination.location
AND c_death.date = c_vaccination.date
WHERE c_death.continent IS NOT NULL
ORDER BY continent, location, date

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date, population,new_vaccination, RollingPeopleVaccinated)
AS 
(
SELECT c_death.continent, c_death.location, c_death.date, c_death.population, c_vaccination.new_vaccinations
, SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY c_death.location ORDER BY c_death.location, c_death.date) AS RollingPeopleVaccinated
FROM PortofolioCovidProject..coviddeaths AS c_death
JOIN PortofolioCovidProject..covidvaccination AS c_vaccination
ON c_death.location = c_vaccination.location
AND c_death.date = c_vaccination.date
WHERE c_death.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

--Use Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT c_death.continent,
       c_death.location,
       c_death.date,
       c_death.population,
       c_vaccination.new_vaccinations,
       SUM(CAST(c_vaccination.new_vaccinations AS BIGINT)) OVER (PARTITION BY c_death.location ORDER BY c_death.location, c_death.date) AS RollingPeopleVaccinated
FROM PortofolioCovidProject..coviddeaths AS c_death
JOIN PortofolioCovidProject..covidvaccination AS c_vaccination
    ON c_death.location = c_vaccination.location
    AND c_death.date = c_vaccination.date
WHERE c_death.continent IS NOT NULL
ORDER BY c_death.location, c_death.date;

SELECT *,
       (RollingPeopleVaccinated / CAST(Population AS numeric)) * 100 AS PercentagePopulationVaccinated
FROM #PercentPopulationVaccinated;

--Creating views to store data for visualizations

CREATE VIEW Percent_PopulationVaccinated AS
SELECT c_death.continent, c_death.location, c_death.date, c_death.population, c_vaccination.new_vaccinations
, SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY c_death.location ORDER BY c_death.location, c_death.date) AS RollingPeopleVaccinated
FROM PortofolioCovidProject..coviddeaths AS c_death
JOIN PortofolioCovidProject..covidvaccination AS c_vaccination
ON c_death.location = c_vaccination.location
AND c_death.date = c_vaccination.date
WHERE c_death.continent IS NOT NULL
--ORDER BY continent, location, date

CREATE VIEW CovidDaily_GlobalNumbers AS
SELECT date, location, SUM(new_cases) AS Daily_cases, SUM(new_deaths) AS Total_deaths, SUM(total_cases) AS Globaltotalcases
From PortofolioCovidProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY date, location
--ORDER BY date

CREATE VIEW IndonesiaTotal_Cases AS
SELECT date, location, SUM(new_cases) AS Daily_cases, SUM(new_deaths) AS Total_deaths, SUM(total_cases) AS Total_cases
From PortofolioCovidProject..coviddeaths
WHERE location = 'Indonesia'
AND continent IS NOT NULL
GROUP BY date, location
--ORDER BY 1, 2
