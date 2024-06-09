Select *
From PortfolioProject..CovidDeaths
Order by 3, 4

Select *
From PortfolioProject..CovidDeaths
Where continent is not null --lọc ra các quốc gia bỏ ra các châu lục
Order by 3, 4

Select *
From PortfolioProject..CovidDeaths
Where continent is null
Order by 3, 4


Select *
From PortfolioProject..CovidVaccinations
Order by 3, 4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1, 2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your city

Select Location, date, total_cases, total_deaths, (cast(total_deaths as FLOAT)/cast(total_cases as FLOAT))*100 as DeathPercentage --khi có thông báo sai dạng cần thêm 'cast', phần FLOAT để chia ra số thập phân
From PortfolioProject..CovidDeaths
Where Location like 'United States'
Order by 1,2

--Looking at Total Cases vs Population
--Show what percentage of population got covid

Select Location, date, total_cases, population, (cast(total_cases as FLOAT)/cast(population as FLOAT))*100 as DeathPercentage --khi có thông báo sai dạng dữ liệu cần thêm 'cast', phần FLOAT để chia ra số thập phân
From PortfolioProject..CovidDeaths
--Where Location like 'United States'
Order by 1,2


--Looking at Countries with Highest Infection Rate compared to Population

Select Location, population, MAX (total_cases) as HighestInfectionCount, MAX((cast(total_cases as FLOAT)/cast(population as FLOAT)))*100 as PercentPopulationInfected --khi có thông báo sai dạng dữ liệu cần thêm 'cast', phần FLOAT để chia ra số thập phân
From PortfolioProject..CovidDeaths
--Where Location like 'United States'
Group by Location, population
Order by PercentPopulationInfected desc

--Showing Coutries with Highest Death Count per Population

Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by location
Order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT

Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by continent
Order by TotalDeathCount desc

--Showing continents with the highest death count per population

Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by continent
Order by TotalDeathCount desc

--Global numbers

Select 
	date, 
	SUM(cast(new_cases as float)) AS Total_Cases, 
	SUM(cast(new_deaths as float)) AS Total_deaths,
	CASE
	WHEN SUM(CAST(new_cases as float)) = 0 THEN 0
	ELSE (SUM(CAST(new_deaths as float)) / SUM(CAST(new_cases as float)))*100
	END AS DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1, 4

SELECT -- cách 2
    date, 
    SUM(CAST(new_cases AS INT)) AS TotalNewCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths,
    CASE 
	WHEN SUM(CAST(new_cases AS INT)) = 0 THEN 0
	ELSE (SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(CAST(new_cases AS INT))) --*100.0 đễ ra số thập phân khi dùng int
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 4

--
Select 
	SUM(cast(new_cases as float)) AS Total_Cases, 
	SUM(cast(new_deaths as float)) AS Total_deaths,
	CASE
	WHEN SUM(CAST(new_cases as float)) = 0 THEN 0
	ELSE (SUM(CAST(new_deaths as float)) / SUM(CAST(new_cases as float)))*100
	END AS DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
Order by 1,2



--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --cộng dồn
--, (RollingPeopleVaccinated/population)*100 --bị lỗi Invalid column name 'RollingPeopleVaccinated' -> dùng CTE hoặc Bảng phụ
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Order by 2,3


--Use CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --cộng dồn
--, (RollingPeopleVaccinated/population)*100 --bị lỗi Invalid column name 'RollingPeopleVaccinated'(1) -> dùng CTE
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null)
Select *, (RollingPeopleVaccinated/population)*100 --khắc phục được lỗi (1)
From PopVsVac


--TEMP TABLE bảng phụ

IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') is not null -- kiểm tra bảng phụ
DROP TABLE #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --cộng dồn
--, (RollingPeopleVaccinated/population)*100 --bị lỗi Invalid column name 'RollingPeopleVaccinated'
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100 --khắc phục được lỗi (1)
From #PercentPopulationVaccinated

--**Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --cộng dồn
--, (RollingPeopleVaccinated/population)*100 --bị lỗi Invalid column name 'RollingPeopleVaccinated'
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null

Select *
From PercentPopulationVaccinated