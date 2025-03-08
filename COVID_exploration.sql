SELECT location, `date`, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, `date`;

SELECT *
FROM coviddeaths
WHERE continent = '';

-- CHANGE DATE COLUMN FROM TEXT TO DATE FORMAT
SELECT `date`, 
STR_TO_DATE(`date`, '%d/%m/%Y')
FROM coviddeaths;

UPDATE coviddeaths
SET `date` = STR_TO_DATE(`date`, '%d/%m/%Y');

ALTER TABLE coviddeaths
MODIFY COLUMN `date` DATE;


-- LOOKING AT TOTAL CASES VS TOTAL DEATHS

SELECT location, `date`, total_cases, total_deaths, (total_deaths/total_cases)*100 AS total_death_percentage
FROM coviddeaths
WHERE location = 'Ireland'
ORDER BY location, `date`;

-- LOOKING AT TOTAL_CASES VS POPULATION

SELECT location, `date`, total_cases, population, (total_cases/population)*100 AS total_cases_percentage
FROM coviddeaths
WHERE location = 'Ireland'
ORDER BY location, `date`;

-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population))*100 AS total_cases_percentage
FROM coviddeaths
GROUP BY location, population
ORDER BY total_cases_percentage DESC;

-- LOOKING AT COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT total_deaths
FROM coviddeaths;

UPDATE coviddeaths
SET total_deaths = '0' WHERE total_deaths = '';

ALTER TABLE coviddeaths
MODIFY COLUMN total_deaths INT;

SELECT location, MAX(total_deaths) AS highest_death_count, population, MAX((total_deaths/population))*100 AS total_deaths_percentage
FROM coviddeaths
WHERE continent != ''
GROUP BY location, population
ORDER BY highest_death_count DESC;

-- BREAKING THINGS DOWN BY CONTINENT

SELECT continent, MAX(total_deaths) AS highest_death_count
FROM coviddeaths
WHERE continent != ''
GROUP BY continent
ORDER BY highest_death_count DESC;

-- GLOBAL NUMBERS

SELECT new_deaths
FROM coviddeaths;

UPDATE coviddeaths
SET new_deaths = '0' WHERE new_deaths = '';

ALTER TABLE coviddeaths
MODIFY COLUMN new_deaths INT;

SELECT `date`, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM coviddeaths
WHERE continent != ''
GROUP BY `date`
ORDER BY `date`;

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM coviddeaths
WHERE continent != '';

-- LOOKING AT VACCINATIONS

SELECT *
FROM covidvaccinations;

SELECT `date`, 
STR_TO_DATE(`date`, '%d/%m/%Y')
FROM covidvaccinations;

UPDATE covidvaccinations
SET `date` = STR_TO_DATE(`date`, '%d/%m/%Y');

ALTER TABLE covidvaccinations
MODIFY COLUMN `date` DATE;

SELECT *
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.`date` = vac.`date`;
    
-- LOOKING AT TOTAL POPULATION VS VACCINATIONS

UPDATE covidvaccinations
SET new_vaccinations = '0' WHERE new_vaccinations = '';

ALTER TABLE covidvaccinations
MODIFY COLUMN new_vaccinations INT;

SELECT location, `date`, new_vaccinations
FROM covidvaccinations;

SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS new_vaccinations_rolling_total
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.`date` = vac.`date`
WHERE dea.continent != ''
ORDER BY 2, 3; 

-- MAKE new_vaccinations_running_total AS A PERCENTAGE OF THE POPULATION

-- WITH CTE

WITH vac_percentage AS
(SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS new_vaccinations_rolling_total
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.`date` = vac.`date`
WHERE dea.continent != ''
ORDER BY 2, 3)
SELECT continent, 
location, 
`date`, 
new_vaccinations,
new_vaccinations_running_total,
population, 
(new_vaccinations_rolling_total/population)*100 AS new_vac_percentage
FROM vac_percentage;

-- TEMP TABLE 

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
`date` date,
population int,
new_vaccinations int,
new_vaccinations_rolling_total int
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS new_vaccinations_rolling_total
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.`date` = vac.`date`
WHERE dea.continent != ''
ORDER BY 2, 3;

SELECT *, (new_vaccinations_rolling_total/population)*100 AS new_vac_percentage
FROM PercentPopulationVaccinated;

-- CREATING VIEW TO STORE FOR LATER VISUALISATIONS

CREATE VIEW PerPopVac AS 
SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS new_vaccinations_rolling_total
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.`date` = vac.`date`
WHERE dea.continent != ''
ORDER BY 2, 3;



