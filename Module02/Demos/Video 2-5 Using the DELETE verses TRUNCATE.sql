/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Flush and Fill: Delete vs Truncate
 USE [DWAdventureWorksLT2012v1]
 go

-- Scenario:  Each day we fill the DimCustomers table with current data
INSERT INTO [DWAdventureWorksLT2012v1].[dbo].[DimCustomers]
( [CustomerID]
, [ContactFullName]
, [CompanyName]
, [MainOfficeCity]
, [MainOfficeStateProvince]
, [MainOfficeCountryRegion]
)
SELECT 
	  [CustomerID] = T1.CustomerID
	, [CompanyName] = Cast(CompanyName as nvarchar(200))
	, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
	, [MainOfficeCity] = T3.City
    , [MainOfficeStateProvince] = T3.StateProvince 
    , [MainOfficeCountryRegion] = T3.CountryRegion
FROM [AdventureWorksLT2012].[SalesLT].[Customer] as T1
JOIN  [AdventureWorksLT2012].[SalesLT].[CustomerAddress] as T2
	On T1.CustomerID = T2.CustomerID
JOIN  [AdventureWorksLT2012].[SalesLT].[Address] as T3
	On T2.AddressID = T3.AddressID
WHERE T2.AddressType = 'Main Office';
go

-- Current Data In DimCustomers 
SELECT 
	 [CustomerKey]
	,[CustomerID]
	,[ContactFullName]
	,[CompanyName]
	,[MainOfficeCity]
	,[MainOfficeStateProvince]
	,[MainOfficeCountryRegion]
FROM [DWAdventureWorksLT2012v1].[dbo].[DimCustomers]
go

-- Now let's Flush the data to prepare for new data using the SQL Delete statement
DELETE FROM dbo.DimCustomers;
go


-- Now let's Flush the data to prepare for new data using the SQL Truncate statement
TRUNCATE TABLE dbo.DimCustomers;
go

ALTER TABLE dbo.FactSales DROP CONSTRAINT 
	fkFactSalesToDimCustomers;
go

TRUNCATE TABLE dbo.DimCustomers;
go



