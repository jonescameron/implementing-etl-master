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
-- Create ETL Views
--********************************************************************--
If (object_id('vETLDimCustomersData') is not null) Drop View vETLDimCustomersData;
go
CREATE VIEW vETLDimCustomersData
AS
	SELECT	CustomerID,
			CompanyName,
			FirstName + ' ' + LastName AS ContactFullName
	FROM	AdventureWorksLT2012.SalesLT.Customer
go

If (object_id('vETLDimProductsData') is not null) Drop View vETLDimProductsData;
go
CREATE VIEW vETLDimProductsData
AS
	SELECT	prd.ProductID,
			prd.[Name] AS ProductName,
			ISNULL(CAST(prd.Color AS NVARCHAR(50)), 'Not Defined') AS ProductColor,
			prd.ListPrice AS ProductListPrice,
			ISNULL(prd.Size, -5) AS ProductSize,
			prd.[Weight] AS ProductWeight,
			pc.ProductCategoryID,
			pc.[Name] AS ProductCategoryName
	FROM	AdventureWorksLT2012.SalesLT.Product prd
			INNER JOIN AdventureWorksLT2012.SalesLT.ProductCategory pc ON prd.ProductCategoryID = pc.ProductCategoryID
go

If (object_id('vETLFactSalesData') is not null) Drop View vETLFactSalesData;
go
CREATE VIEW vETLFactSalesData
AS
	SELECT	ord.SalesOrderID,
			ord.SalesOrderDetailID,
			cst.CustomerKey, --AS CustomerKey,
			prd.ProductKey, --AS ProductKey,
			od.CalendarDateKey AS OrderDateKey,
			sd.CalendarDateKey AS ShipDateKey,
			ord.OrderQty,
			ord.UnitPrice,
			ord.UnitPriceDiscount
	FROM	AdventureWorksLT2012.SalesLT.SalesOrderDetail ord
			INNER JOIN AdventureWorksLT2012.SalesLT.SalesOrderHeader oh ON ord.SalesOrderID = oh.SalesOrderID
			INNER JOIN DWAdventureWorksLT2012Lab01.dbo.DimCustomers cst ON oh.CustomerID = cst.CustomerID
			INNER JOIN DWAdventureWorksLT2012Lab01.dbo.DimProducts prd ON ord.ProductID = prd.ProductID
			INNER JOIN DWAdventureWorksLT2012Lab01.dbo.DimDates od ON CAST(oh.OrderDate AS DATE) = CAST(od.CalendarDate AS DATE)
			INNER JOIN DWAdventureWorksLT2012Lab01.dbo.DimDates sd ON CAST(oh.ShipDate AS DATE) = CAST(sd.CalendarDate AS DATE)

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
	  [CustomerID]
	, [CompanyName]
	, [ContactFullName]
FROM  [DWAdventureWorksLT2012Lab01].[dbo].[vETLDimCustomersData]
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
	  [ProductID]
	, [ProductName]
	, [ProductColor]
	, [ProductListPrice]
	, [ProductSize]
	, [ProductWeight]
	, [ProductCategoryID]
	, [ProductCategoryName]
FROM  [DWAdventureWorksLT2012Lab01].[dbo].[vETLDimProductsData]
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
	  [SalesOrderID]  
	, [SalesOrderDetailID] 
	, [CustomerKey]
	, [ProductKey]
	, [OrderDateKey]
	, [ShipDateKey]
	, [OrderQty]
	, [UnitPrice]
	, [UnitPriceDiscount]
FROM [DWAdventureWorksLT2012Lab01].[dbo].[vETLFactSalesData] 
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
