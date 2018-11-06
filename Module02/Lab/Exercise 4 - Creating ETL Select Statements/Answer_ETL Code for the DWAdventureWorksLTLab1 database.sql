/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/


 --****************** [ DWAdventureWorksLT2012Lab1 ETL Code ] *********************--
-- This file will flush and fill the sales data mart in the DWAdventureWorksLT2012Lab1 database
--***********************************************************************************************--
Use DWAdventureWorksLT2012Lab01;
go

 
--********************************************************************--
-- Drop Foreign Key Constraints
--********************************************************************--

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesToDimProducts;

ALTER TABLE dbo.FactSales DROP CONSTRAINT 
	fkFactSalesToDimCustomers;

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesOrderDateToDimDates;

ALTER TABLE dbo.FactSales DROP CONSTRAINT
	fkFactSalesShipDateDimDates;			

--********************************************************************--
-- Clear Table Data
--********************************************************************--

TRUNCATE TABLE dbo.FactSales;
TRUNCATE TABLE dbo.DimCustomers;
TRUNCATE TABLE dbo.DimProducts; 
  

--********************************************************************--
-- Fill Dimension Tables
--********************************************************************--

-- DimCustomers
INSERT INTO [DWAdventureWorksLT2012Lab01].[dbo].[DimCustomers]
( [CustomerID]
, [CompanyName]
, [ContactFullName]
)
SELECT 
	  [CustomerID] = T1.CustomerID
	, [CompanyName] = Cast(CompanyName as nvarchar(200))
	, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
FROM [AdventureWorksLT2012].[SalesLT].[Customer] as T1
go

-- DimProducts
INSERT INTO [DWAdventureWorksLT2012Lab01].[dbo].[DimProducts]
( [ProductID]
, [ProductName]
, [ProductColor]
, [ProductListPrice]
, [ProductSize]
, [ProductWeight]
, [ProductCategoryID]
, [ProductCategoryName]
)
SELECT 
    [ProductID] = T1.[ProductID]
  , [ProductName] = T1.[Name]
  , [ProductColor] = IsNull( Cast( T1.[Color]  as nvarchar(50)), 'Not Defined') 
  , [ProductListPrice] =T1.[ListPrice]
  , [ProductSize] = IsNull( T1.[Size], -5) -- A value could be entered, but the source data has not yet defined it
  , [ProductWeight] = T1.[Weight] -- Leave null for proper weight calculations
  , [ProductCategoryID] = T2.[ProductCategoryID]
  , [ProductCategoryName] = T2.[Name]
FROM [AdventureWorksLT2012].[SalesLT].[Product] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
ON T1.ProductCategoryID = T2.ProductCategoryID
go

--********************************************************************--
-- Fill Fact Tables
--********************************************************************--

-- Fill Fact Sales 
INSERT INTO [DWAdventureWorksLT2012Lab01].[dbo].[FactSales]
( [SalesOrderID]
, [SalesOrderDetailID]
, [CustomerKey]
, [ProductKey]
, [OrderDateKey]
, [ShipDateKey]
, [OrderQty]
, [UnitPrice]
, [UnitPriceDiscount]
)
SELECT 
	  T1.[SalesOrderID]  
	, [SalesOrderDetailID] 
	, T3.[CustomerKey]
	, T4.[ProductKey]
	, [OrderDateKey] = T5.CalendarDateKey
	, [ShippedDateKey] = T6.CalendarDateKey
	, [OrderQty]
	, [UnitPrice]
	, [UnitPriceDiscount]
	FROM [AdventureWorksLT2012].[SalesLT].[SalesOrderDetail] as T1
	JOIN [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader] as T2
	 ON T1.[SalesOrderID] = T2.[SalesOrderID]
	JOIN [DWAdventureWorksLT2012Lab01].[dbo].[DimCustomers] as T3
	 ON T2.[CustomerID] = T3.[CustomerID]
	JOIN [DWAdventureWorksLT2012Lab01].[dbo].[DimProducts] as T4
	 ON T4.[ProductID] = T1.[ProductID]
	JOIN [DWAdventureWorksLT2012Lab01].[dbo].[DimDates] as T5
	 ON Cast(T5.CalendarDate as Date) = Cast(T2.[OrderDate] as Date)
	JOIN [DWAdventureWorksLT2012Lab01].[dbo].[DimDates] as T6
	 ON Cast(T6.CalendarDate as Date) = Cast(T2.[ShipDate] as Date)  
	go

--********************************************************************--
-- Replace Foreign Key Constraints
--********************************************************************--
ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesToDimProducts FOREIGN KEY (ProductKey) 
	REFERENCES dbo.DimProducts	(ProductKey);

ALTER TABLE dbo.FactSales ADD CONSTRAINT 
	fkFactSalesToDimCustomers FOREIGN KEY (CustomerKey) 
	REFERENCES dbo.DimCustomers (CustomerKey);
 
ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesOrderDateToDimDates FOREIGN KEY (OrderDateKey) 
	REFERENCES dbo.DimDates(CalendarDateKey);

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesShipDateDimDates FOREIGN KEY (ShipDateKey)
	REFERENCES dbo.DimDates (CalendarDateKey);
 
 
--********************************************************************--
-- Verify that the tables are filled
--********************************************************************--
-- Dimension Tables


SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimCustomers]; 


SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimProducts]; 



SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[DimDates]; 

-- Fact Tables 


SELECT * FROM [DWAdventureWorksLT2012Lab01].[dbo].[FactSales]; 
