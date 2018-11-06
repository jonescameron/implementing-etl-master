/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

--****************** [DWAdventureWorksLT2012v1] *********************--
-- This file will drop and create the DWAdventureWorksLT2012v1
-- database, with all its objects. 
--********************************************************************--

USE [master];
If Exists (Select Name from SysDatabases Where Name = 'DWAdventureWorksLT2012v1')
  Begin
   Alter database DWAdventureWorksLT2012v1 set single_user with rollback immediate;
   Drop database DWAdventureWorksLT2012v1;
  End
go
CREATE DATABASE DWAdventureWorksLT2012v1;
go
USE DWAdventureWorksLT2012v1;
go

--********************************************************************--
-- Create the Tables
--********************************************************************--
CREATE -- Customers Dimension
TABLE DimCustomers
( CustomerKey int Not Null CONSTRAINT [pkDimCustomers] PRIMARY KEY Identity(1,1)
, CustomerID int Not Null
, ContactFullName nvarchar(200) Not Null 
, CompanyName nvarchar(200) Not Null
, MainOfficeCity nvarchar(50) Not Null 
, MainOfficeStateProvince nvarchar(50) Not Null 
, MainOfficeCountryRegion nvarchar(50) Not Null  
);
go

CREATE -- Products Dimension 
TABLE DimProducts	
( ProductKey int Not Null CONSTRAINT [pkDimProducts] PRIMARY KEY Identity(1,1)
, ProductID int Not Null 
, ProductName nvarchar(50) Not Null
, ProductNumber nvarchar(50) Not Null 
, ProductColor nvarchar(50) Not Null 
, ProductStandardCost money Not Null 
, ProductListPrice money Not Null  
, ProductSize nvarchar(5) Not Null
, ProductWeight decimal(8,2 ) Not Null
, ProductCategoryID int Not Null
, ProductCategoryName nVarchar(50) Not Null
);
go

CREATE -- Dates Dimension  
TABLE DimDates	
( CalendarDateKey int Not Null CONSTRAINT [pkDimDates] PRIMARY KEY
, CalendarDateName nvarchar(50) Not Null 
, CalendarYearMonthID int Not Null 
, CalendarYearMonthName nvarchar(50) Not Null 
, CalendarYearQuarterID int Not Null 
, CalendarYearQuarterName nvarchar(50) Not Null 
, CalendarYearID int Not Null 
, CalendarYearName nvarchar(50) Not Null
, CalendarDate Date Not Null  
, FiscalDate Date Not Null 
);
go

CREATE -- Primary Fact table for the Sales Data Mart
TABLE FactSales	
( SalesOrderID int
, SalesOrderDetailID int
, CustomerKey int -- FK to DimCustomers
, ProductKey int -- FK to DimProducts
, OrderDateKey int -- FK to DimDates
, ShipDateKey int -- FK to DimDates
, OrderQty smallint
, UnitPrice money
, UnitPriceDiscount money
, CONSTRAINT [pkFactSales] PRIMARY KEY 
	(
	  SalesOrderID
	, SalesOrderDetailID
	, CustomerKey
	, ProductKey
	, OrderDateKey
	)
);
go

--********************************************************************--
-- Create the Foreign Key CONSTRAINTs
--********************************************************************--
ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesToDimProducts FOREIGN KEY (ProductKey) 
	REFERENCES dbo.DimProducts	(ProductKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT 
	fkFactSalesToDimCustomers FOREIGN KEY (CustomerKey) 
	REFERENCES dbo.DimCustomers (CustomerKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesOrderDateToDimDates FOREIGN KEY (OrderDateKey) 
	REFERENCES dbo.DimDates(CalendarDateKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesShipDateDimDates FOREIGN KEY (ShipDateKey)
	REFERENCES dbo.DimDates (CalendarDateKey);
go

Select 'Version 1 of the database was created';