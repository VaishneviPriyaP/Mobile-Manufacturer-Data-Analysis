--SQL Advance Case Study


--Q1--BEGIN 
--1. List all the states in which we have customers who have bought cellphones from 2005 till today. 

select distinct dl.State
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_LOCATION] as dl 
on ft.IDLocation = dl.IDLocation
where YEAR(Date) between 2005 and YEAR(getdate());




--Q1--END

--Q2--BEGIN
--2. What state in the US is buying the most 'Samsung' cell phones?

with 
	temp
	as
	(	select IDLocation,sum(Quantity)as Total_Quantity , rank() over ( order by sum(Quantity) desc) RankId
		from [dbo].[FACT_TRANSACTIONS]
		where IDLocation in ( select IDLocation
							  from [dbo].[DIM_LOCATION]
							  where Country = 'US')

		and	  IDModel in    (select dmo.IDModel
							 from [dbo].[DIM_MODEL] as dmo
							 join [dbo].[DIM_MANUFACTURER] as dma
							 on dmo.IDManufacturer = dma.IDManufacturer
							 where dma.Manufacturer_Name = 'Samsung')
		group by IDLocation)

SELECT dl.State
 FROM temp as t
 join [dbo].[DIM_LOCATION] as dl
 on t.IDLocation=dl.IDLocation
 WHERE t.RankId = 1







--Q2--END

--Q3--BEGIN      
--3. Show the number of transactions for each model per zip code per state. 	

select distinct dl.ZipCode,dl.State, ft.IDModel ,dm.Model_Name, count( dm.Model_Name) as Models_Transaction_Count
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_MODEL] as dm
on ft.IDModel= dm.IDModel
join [dbo].[DIM_LOCATION] as dl
on ft.IDLocation = dl.IDLocation
group by dl.ZipCode, dl.State, ft.IDModel, dm.Model_Name;








--Q3--END

--Q4--BEGIN
--4. Show the cheapest cellphone (Output should contain the price also)

select IDModel,Model_Name,Unit_price   
from [dbo].[DIM_MODEL]
where unit_price = (select MIN(unit_price) from [dbo].[DIM_MODEL])





--Q4--END

--Q5--BEGIN

--5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price. 


select top 5 SUM(ft.Quantity) as Total_Quantity , ft.IDModel,dma.Manufacturer_Name, AVG(ft.TotalPrice) as Average_Total_Price
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_MODEL] as dmo
on ft.IDModel = dmo.IDModel
join [dbo].[DIM_MANUFACTURER] as dma
on dmo.IDManufacturer = dma.IDManufacturer
group by ft.IDModel, dma.Manufacturer_Name
order by Average_Total_Price desc 










--Q5--END

--Q6--BEGIN
--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500

select ft.IDCustomer,dc.Customer_Name,AVG(TotalPrice) as Average_Price
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_CUSTOMER] as dc
on ft.IDCustomer = dc.IDCustomer
where year(Date) = '2009'
group by ft.IDCustomer,dc.Customer_Name
having AVG(TotalPrice) > 500 ;









--Q6--END
	
--Q7--BEGIN  
--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010	
-- INTERSECT did not work for me 

select a.IDModel 
from
(select top 5 IDModel,sum(Quantity) as Total_Quantity
from [dbo].[FACT_TRANSACTIONS]
where YEAR(date) = '2008'  
group by IDModel
order by Total_Quantity desc) a
inner join 
(select top 5 IDModel,sum(Quantity) as Total_Quantity
from [dbo].[FACT_TRANSACTIONS]
where YEAR(date) = '2009'
group by IDModel
order by Total_Quantity desc) b
on a.IDModel = b.IDModel
inner join
(select top 5 IDModel,sum(Quantity) as Total_Quantity
from [dbo].[FACT_TRANSACTIONS]
where YEAR(date) = '2010'
group by IDModel
order by Total_Quantity desc
) c
on c.IDModel = b.IDModel















--Q7--END	
--Q8--BEGIN
--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.

	(select a.IDModel,dm.IDManufacturer,dma.Manufacturer_Name,Model_Rank
	from
	(SELECT IDModel,sum(TotalPrice) as TotalPrice ,DENSE_RANK() OVER (ORDER BY sum(TotalPrice) Desc) AS Model_Rank 
	FROM [dbo].[FACT_TRANSACTIONS]
	where YEAR(date) = 2009
	group by IDModel) a
	join [dbo].[DIM_MODEL] as dm
	on a.IDModel = dm.IDModel
	join [dbo].[DIM_MANUFACTURER] as dma
	on dm.IDManufacturer = dma.IDManufacturer
	where a.Model_Rank=2)
	union
	(select b.IDModel,dm.IDManufacturer,dma.Manufacturer_Name,Model_Rank
	from
	(SELECT IDModel,sum(TotalPrice) as TotalPrice ,DENSE_RANK() OVER (ORDER BY sum(TotalPrice) Desc) AS Model_Rank 
	FROM [dbo].[FACT_TRANSACTIONS]
	where YEAR(date) = 2010
	group by IDModel) b
	join [dbo].[DIM_MODEL] as dm
	on b.IDModel = dm.IDModel
	join [dbo].[DIM_MANUFACTURER] as dma
	on dm.IDManufacturer = dma.IDManufacturer
	where b.Model_Rank=2)
















--Q8--END
--Q9--BEGIN
--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. 

(select distinct dmo.IDManufacturer,dma.Manufacturer_Name
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_MODEL] as dmo
on  ft.IDModel = dmo.IDModel
join [dbo].[DIM_MANUFACTURER] as dma
on dmo.IDManufacturer=dma.IDManufacturer
where year(date) = 2010)
except
(select distinct dmo.IDManufacturer,dma.Manufacturer_Name
from [dbo].[FACT_TRANSACTIONS] as ft
join [dbo].[DIM_MODEL] as dmo
on  ft.IDModel = dmo.IDModel
join [dbo].[DIM_MANUFACTURER] as dma
on dmo.IDManufacturer=dma.IDManufacturer
where year(date) = 2009)
















--Q9--END

--Q10--BEGIN
	
select IDCustomer,Year,Average_TotalPrice, previous_Average_TotalPrice,
		 ROUND(((Average_TotalPrice - previous_Average_TotalPrice ) /nullif(previous_Average_TotalPrice,0)) * 100 ,0) as Percent_Price_Change
	from
		(SELECT top 10 IDCustomer,YEAR(Date) as Year,AVG(TotalPrice) as Average_TotalPrice,		
				LAG(AVG(TotalPrice),1,0) OVER (PARTITION BY IDCustomer ORDER BY YEAR(Date)) previous_Average_TotalPrice
		from [dbo].[FACT_TRANSACTIONS]
		group by IDCustomer,YEAR(Date)) as t


















--Q10--END
	