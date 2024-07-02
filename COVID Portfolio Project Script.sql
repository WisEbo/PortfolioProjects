Portfolio project 


SELECT * FROM  CovidDeaths
ORDER BY 3,4;

-- SELECT * FROM CovidVaccinations
-- ORDER BY 3,4;


-- Select the data we will be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;


-- total cases vs total deaths HOw many that died actually had covid

-- Shows the likelihood of dying if you get covid in your country

SELECT Location, date, 	total_cases, 	total_deaths, (CAST( total_deaths AS REAL )/CAST(total_cases AS REAL) ) *100 AS DeathPErcentage

FROM 
	CovidDeaths
	
WHERE location LIKE '%Kingdom%'

ORDER BY 
	1,2;


-- looking at the 	total case vs the population
-- Shows what percentage of the population got covid
SELECT 
	Location, 
	date, 	
	total_cases, 
	population, 
	(CAST( total_cases AS REAL )/CAST(population AS REAL) ) *100 AS PercentageOfPopulationInfectedted

FROM 
	CovidDeaths
WHERE 
	location LIKE '%kingdom%'
ORDER BY 
	1,2;

	
-- 	Looking at countries that had the highest infection rate compared to population
SELECT 
	Location, 
	MAX(total_cases) as HighestCaesCountPrerLocation, 
	population, 
	(CAST( MAX(total_cases) AS REAL )/CAST(population AS REAL) ) *100  AS PercentageOfPopulationInfectedted

FROM 
	CovidDeaths

GROUP BY 
	location, population

ORDER BY 
	PercentageOfPopulationInfectedted DESC;

	
-- Showing countries with the highest death count per population
SELECT 
	Location, 
	date,
	MAX(CAST(total_deaths AS INTEGER)) as TotlaDeathCount
FROM 
	CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location

ORDER BY 
	TotlaDeathCount DESC;


	
-- 	Breaking  it down by continent
-- Showing the continent with the highest death count		

SELECT 
	continent, 
	date,
	MAX(CAST(total_deaths AS INTEGER)) as TotlaDeathCount
FROM 
	CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	continent

ORDER BY 
	TotlaDeathCount DESC
	
	
	
-- Showing the continent with the highest death count	2
SELECT 	Location, 	MAX(CAST(total_deaths AS INTEGER)) as TotlaDeathCount

FROM 	CovidDeaths

WHERE continent IS  NULL AND location NOT LIKE '%income'

GROUP BY location

ORDER BY 	TotlaDeathCount DESC


-- Global numbers
SELECT 
	date, 
	sum(CAST(new_cases as REAL)) AS total_cases_calc, 
	sum(CAST (new_deaths AS REAL)) AS total_deaths_calc, 
	(sum(CAST (new_deaths AS REAL)) / sum(CAST (new_cases AS REAL )) ) * 100 AS DeathPercentage
-- 	(cast(total_deaths AS REAL) / CAST(total_cases AS REAL)) * 100 AS DeathPercentage
FROM 	CovidDeaths

WHERE continent is NOT NULL

-- GROUP BY date 

ORDER BY 	1,2;
	
-- joining the tables	
-- looking at total populations vs vaccinated - how many people in the world have been vaccinated	
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,  
    dea.population, 
    vac.new_vaccinations
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 
    2, 3;
	
	
-- 	-new vacs per day lets do a rolling count  
-- totla amoiunts of vaccination
	SELECT 
    dea.continent, 
    dea.location, 
    dea.date,  
    dea.population, 
    vac.new_vaccinations,
	sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 
    2, 3;
	
	
-- 	total population vs vaccinations divide by the people in the population to know how many people in that country are vaccinated 
-- we either use a cte or temp table 

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,  
    dea.population, 
    vac.new_vaccinations,
	sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
	)
	
SELECT 
	*, (RollingPeopleVaccinated/population)  * 100
FROM 
	PopVsVac;
	
-- Cleaner	
	WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date,  
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM 
        CovidDeaths dea
    JOIN 
        CovidVaccinations vac
    ON 
        dea.location = vac.location
    AND 
        dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
    AND 
        vac.new_vaccinations IS NOT NULL
)
SELECT 
    * , (RollingPeopleVaccinated/population) *100
FROM 
    PopVsVac;
	
	
-- 	Temp table

-- Create a temporary table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated (
    continent TEXT, 
    location TEXT, 
    date DATETIME,  
    population REAL, 
    new_vaccinations REAL,
    RollingPeopleVaccinated REAL
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,  
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
AND 
    vac.new_vaccinations IS NOT NULL;

-- Select from the temporary table and calculate the percentage of the population vaccinated
SELECT 
    *,
    (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM
    PercentPopulationVaccinated;
	
	
	
-- 	creating view too store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date,  
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
AND 
    vac.new_vaccinations IS NOT NULL;
	
	
	SELECT *
	
	FROM
		PercentPopulationVaccinated;



