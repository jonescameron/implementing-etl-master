 /*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

 --****************** [ DWAdventureWorksLT2012Lab02 ETL Code ] *********************--
-- This file will flush and fill the sales data mart in the DWAdventureWorksLT2012Lab02 database
--***********************************************************************************************--
Use DWAdventureWorksLT2012Lab02;
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
Declare @ReturnCode int
Execute @ReturnCode = pETLFillDimCustomers
Select [Return Status for pETLFillDimCustomers ] = @ReturnCode
go

-- DimProducts
Declare @ReturnCode int
Execute @ReturnCode = pETLFillDimProducts
Select [Return Status for pETLFillDimProducts] = @ReturnCode
go

--********************************************************************--
-- Fill Fact Tables
--********************************************************************--

-- Fill Fact Sales 
Declare @ReturnCode int
Execute @ReturnCode = pETLFillFactSales
Select [Return Status for pETLFillFactSales] = @ReturnCode
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
SELECT * FROM [DWAdventureWorksLT2012Lab02].[dbo].[DimCustomers]; 
SELECT * FROM [DWAdventureWorksLT2012Lab02].[dbo].[DimProducts]; 
SELECT * FROM [DWAdventureWorksLT2012Lab02].[dbo].[DimDates]; 

-- Fact Tables 
SELECT * FROM [DWAdventureWorksLT2012Lab02].[dbo].[FactSales]; 
