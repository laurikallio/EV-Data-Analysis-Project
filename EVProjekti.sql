Select *
From  EVDatabase..ElectricVehiclePopulationData

-- autojen m��r� vuoteen n�hden

Select Distinct ModelYear, COUNT(VIN) as EVsPerYear
from EVDatabase..ElectricVehiclePopulationData
Group by ModelYear
Order by ModelYear DESC




-- Mill� automerkill� on pisin ajomatka

Select Distinct Make, Round(AVG(ElectricRange), 0) as AVGRangeMiles
from EVDatabase..ElectricVehiclePopulationData
Where ElectricRange > 1
Group by Make
Order by AVGRangeMiles Desc




-- Automerkitt�in ajomatka eroteltuna BEV ja PHEV
-- En nyt osannut yhdist�� ensimm�isi� kolumneja -- Sain sittenkin COALESCEll�:)

WITH CTE_RangePlugin as
	(Select Distinct Make, Round(AVG(ElectricRange), 0) as AVGRangeMilesPlugin
	from EVDatabase..ElectricVehiclePopulationData
	Where ElectricRange > 1 AND ElectricVehicleType Like 'Plug%'
	Group by Make
)
, CTE_RangeEV as
	(Select Distinct Make, Round(AVG(ElectricRange), 0) as AVGRangeMilesEV
	from EVDatabase..ElectricVehiclePopulationData
	Where ElectricRange > 1 AND ElectricVehicleType Like 'Bat%'
	Group by Make
)

Select COALESCE(EV.Make, plug.Make) as Make, plug.AVGRangeMilesPlugin, EV.AVGRangeMilesEV
From CTE_RangeEV as EV
Full join CTE_RangePlugin as plug 
on EV.Make = plug.Make
Order by AVGRangeMilesplugin DESC



-- Miss� kaupungissa eniten tesloja -- Datan mukaan Seattlessa

Select Distinct City, COUNT(Make) as NumberOfTeslas
From EVDatabase..ElectricVehiclePopulationData
Where Make = 'Tesla'
Group by City
Order by NumberOfTeslas DESC

-- mik� automerkki on yleisin osavaltioittain Keskener�inen

WITH MakeCounts AS (
  SELECT State, Make, COUNT(Make) AS CountOfVehicles
  FROM EVDatabase..ElectricVehiclePopulationData
  GROUP BY State, Make
),
RankedMakes AS (
  SELECT State, Make, CountOfVehicles, ROW_NUMBER() OVER (PARTITION BY State ORDER BY CountOfVehicles DESC) AS RowNum
  FROM MakeCounts
)
SELECT State, Make
FROM RankedMakes
WHERE RowNum = 1;



-- Paljonko Teslan eri mallit maksavat + LIS�KSI otetaan n�iden per��n range (EV_cars) ja akun koko
Select DISTINCT Make, price.Model, Cast(Price#DE# as DECIMAL(10)) as Price, Battery, Range
From EVDatabase..ElectricVehiclePopulationData as data
Full Join EVDatabase..EV_cars as price
	on data.Make = price.Brand
Where Make Like 'Tesla'
Order by Price DESC


-- Mill� automallilla on paras hinta-range-suhde (pienempi luku on parempi) 
-- jostain syyst� osa automerkeist� on kadonnut kuten Citroen e-C3
-- syyselvisi ja t�ss� ei ollut j�rke� k�ytt�� Joinia ollenkaan

Select DISTINCT price.Brand, price.Model, Cast(Price#DE# as DECIMAL(10)) as Price, Battery, Range, (Price#DE# / Range) as PricePerRange
,(Range / Price#DE#)*1000 as MilesPer1000Dollar
From EVDatabase..ElectricVehiclePopulationData as data
Full Join EVDatabase..EV_cars as price
on data.Make = price.Brand
Where TRY_CAST(Price#DE# AS DECIMAL(10)) IS NOT NULL
Order by PricePerRange ASC





--Mik� on halvin ja kallein auto Fairfax Countyss�, ja mihin l�ytyy hinta toisesta taulukosta
Select County, Make, data.Model, AVG(Cast(EV.Price#DE# as DECIMAL(10))) as AVGPrice, ModelYear
From EVDatabase..ElectricVehiclePopulationData as data
Join EVDatabase..EV_cars as EV
	ON data.Model = EV.Model
Where county LIKE 'Fair%'
	AND TRY_CAST(Price#DE# AS DECIMAL(10)) IS NOT NULL
Group by County, Make, ModelYear, data.Model
Order by AVGPrice ASC

-- Taulukoiden yhteisiss� datoissa on puutteita, joten l�ytyi vain Tesla mallit
-- Voisimme yritt�� katsoa merkkikohtaisesti keskihinnat, mutta se ei ole fiksuimmasta p��st�

Select County, Make,  AVG(Cast(EV.Price#DE# as DECIMAL(10))) as AVGPrice, ModelYear
From EVDatabase..ElectricVehiclePopulationData as data
Join EVDatabase..EV_cars as EV
	ON data.Make = EV.Brand
Where county LIKE 'Fair%'
	AND TRY_CAST(Price#DE# AS DECIMAL(10)) IS NOT NULL
Group by County, Make, ModelYear
Order by AVGPrice ASC



