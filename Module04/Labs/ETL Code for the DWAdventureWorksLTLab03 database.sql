 /*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

 --****************** [ DWAdventureWorksLT2012Lab03 ETL Code ] *********************--
-- This file will flush and fill the sales data mart in the DWAdventureWorksLT2012Lab03 database
--***********************************************************************************************--
Use DWAdventureWorksLT2012Lab03;
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

-- Code for Customers Source Data
SELECT 
  [CustomerID] 
, [CompanyName] -- Cast(CompanyName as nvarchar(200))
, [FirstName] -- Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
, [LastName] -- Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

-- Code for Products Source Data
SELECT 
  [ProductID] 
, [ProductName] = T1.[Name]
, [ProductColor] = COLOR -- Cast(IsNull(T1.[Color], 'Not Defined')  as nvarchar(50)) -- USING THE SSIS REPLACENULL(expression 1,expression 2) function
, [ProductListPrice] = T1.[ListPrice]
, [ProductSize] =  SIZE -- Cast( IsNull( T1.[Size], -5) as nvarchar(50)) -- USING THE SSIS REPLACENULL(expression 1,expression 2) function
, [ProductWeight] = T1.[Weight]
, [ProductCategoryID] = T2.[ProductCategoryID]
, [ProductCategoryName] = T2.[Name]
FROM [AdventureWorksLT2012].[SalesLT].[Product] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
ON T1.ProductCategoryID = T2.ProductCategoryID;
go

--********************************************************************--
-- Fill Fact Tables
--********************************************************************--

-- Code for FactSales Source Data
SELECT 
  T1.[SalesOrderID]  
, [SalesOrderDetailID] 
, T3.[CustomerKey]
, T4.[ProductKey]
, [OrderDateKey] = T5.CalendarDateKey
, [ShipDateKey] = T6.CalendarDateKey
, [OrderQty]
, [UnitPrice]
, [UnitPriceDiscount]
FROM [AdventureWorksLT2012].[SalesLT].[SalesOrderDetail] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader] as T2
	ON T1.[SalesOrderID] = T2.[SalesOrderID]
JOIN [DWAdventureWorksLT2012Lab03].[dbo].[DimCustomers] as T3
	ON T2.[CustomerID] = T3.[CustomerID]
JOIN [DWAdventureWorksLT2012Lab03].[dbo].[DimProducts] as T4
	ON T4.[ProductID] = T1.[ProductID]
JOIN [DWAdventureWorksLT2012Lab03].[dbo].[DimDates] as T5
	ON Cast(T5.CalendarDate as Date) = Cast(T2.[OrderDate] as Date)
JOIN [DWAdventureWorksLT2012Lab03].[dbo].[DimDates] as T6
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
SELECT * FROM [DWAdventureWorksLT2012Lab03].[dbo].[DimCustomers]; 
SELECT * FROM [DWAdventureWorksLT2012Lab03].[dbo].[DimProducts]; 
SELECT * FROM [DWAdventureWorksLT2012Lab03].[dbo].[DimDates]; 

-- Fact Tables 
SELECT * FROM [DWAdventureWorksLT2012Lab03].[dbo].[FactSales]; 
