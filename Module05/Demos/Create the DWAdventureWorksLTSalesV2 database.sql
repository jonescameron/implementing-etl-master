/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

--****************** [DWAdventureWorksLT2012V2] *********************--
-- This file will drop and create the DWAdventureWorksLT2012V2
-- database, with all its objects. 
--********************************************************************--

USE [master]
If Exists (Select Name from SysDatabases Where Name = 'DWAdventureWorksLT2012V2')
  Begin
   ALTER DATABASE DWAdventureWorksLT2012V2 set single_user with rollback immediate
   DROP DATABASE DWAdventureWorksLT2012V2
  End
Go
CREATE DATABASE DWAdventureWorksLT2012V2;
GO
USE DWAdventureWorksLT2012V2;
GO

--********************************************************************--
-- Create the Tables
--********************************************************************--
CREATE -- Dimension
TABLE DimCustomers
( CustomerKey int Not Null CONSTRAINT [pkDimCustomers] PRIMARY KEY Identity(1,1)
, CustomerID	int Not Null
, ContactFullName nvarchar(200) Not Null 
, CompanyName nvarchar(200) Not Null 
);

Go


CREATE -- Dimension
TABLE DimAddresses
( AddressKey	int Not Null CONSTRAINT [pkDimAddresses] PRIMARY KEY Identity
, AddressID int Not Null 
, City nvarchar(50) Not Null 
, StateProvince nvarchar(50) Not Null 
, CountryRegion nvarchar(50) Not Null 
);
Go

CREATE -- Bridge table for the many-to-many relationship
TABLE FactCustomersAddresses	
( CustomerKey int Not Null -- FK to DimCustomers
, AddressKey	int Not Null -- FK to DimAddresses
, AddressType nvarchar(50) Not Null
, CONSTRAINT [pkDimCustomersAddreses] PRIMARY KEY 
	(CustomerKey
	, AddressKey
	)
);
Go

CREATE -- Parent-Child Dimension 
TABLE DimProductCategories	
( ProductCategoryKey int Not Null CONSTRAINT [pkDimProductCategories] PRIMARY KEY Identity(100,100) -- Using 100 to demo the parent-child ETL lookup process better
, ProductCategoryID int Not Null
, ParentProductCategoryKey int Null -- Need to leave this null so we can Update to the Surrogate Key after its generated.
, ParentProductCategoryID int  Null -- Need to leave this null so we can Update to the Self Key.
, ProductCategoryName nvarchar(50) Not Null
);
Go

CREATE -- Dimension 
TABLE DimProducts	
( ProductKey int Not Null CONSTRAINT [pkDimProducts] PRIMARY KEY Identity(1,1)
, ProductID int Not Null 
, ProductName nvarchar(50) Not Null
, ProductNumber nvarchar(50) Not Null 
, ProductColor nvarchar(50) Not Null 
, ProductStandardCost money Not Null 
, ProductListPrice	 money Not Null  
, ProductSize	nvarchar(5) Not Null
, ProductWeight decimal(8,2 ) Not Null
, ProductCategoryKey int Not Null  -- FK to DimProductCategories
, ProductModelID int Not Null
, ProductModelName nvarchar(50)
, SellStartDate date Null
, SellEndDate	date Null
, DiscontinuedDate date Null
);
Go


CREATE -- Dimension  
TABLE DimDates	
( CalendarDateKey int Not Null CONSTRAINT [pkDimDates] PRIMARY KEY
, CalendarDateName nvarchar(50) Not Null 
, CalendarYearMonthKey int Not Null 
, CalendarYearMonthName nvarchar(50) Not Null 
, CalendarYearQuarterKey int Not Null 
, CalendarYearQuarterName nvarchar(50) Not Null 
, CalendarYearKey int Not Null 
, CalendarYearName nvarchar(50) Not Null
, CalendarDate Date Not Null  
, FiscalDate Date Not Null 
, WasUSFederalHoliday bit Not Null 
);
Go

CREATE -- Primary Fact table for the Sales Data Mart
TABLE FactSales	
( SalesOrderID int
, SalesOrderDetailID int
, CustomerKey int -- FK to DimCustomers
, ProductKey int -- FK to DimProducts
, OrderDateKey int -- FK to DimDates
, DueDateKey int -- FK to DimDates
, ShipDateKey int -- FK to DimDates
, ShipToAddressKey int -- FK to DimAddresses
, BillToAddressKey int -- FK to DimAddresses
, ShipMethod nvarchar(50)
, OnlineOrderFlag bit
, Status tinyint
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
	, DueDateKey
	, ShipDateKey
	, ShipToAddressKey
	, BillToAddressKey
	, ShipMethod
	, OnlineOrderFlag
	, Status
	)
);
Go

--********************************************************************--
-- Create the Foreign Key CONSTRAINTs
--********************************************************************--
ALTER TABLE dbo.DimProducts ADD CONSTRAINT
	fkDimProductsToDimProductCategories FOREIGN KEY (ProductCategoryKey)
	REFERENCES dbo.DimProductCategories (ProductCategoryKey); 
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesToDimProducts FOREIGN KEY (ProductKey) 
	REFERENCES dbo.DimProducts	(ProductKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT 
	fkFactSalesToDimCustomers FOREIGN KEY (CustomerKey) 
	REFERENCES dbo.DimCustomers (CustomerKey);
go

ALTER TABLE dbo.FactCustomersAddresses ADD CONSTRAINT
	fkFactCustomersAddressesToDimCustomers FOREIGN KEY (CustomerKey) 
	REFERENCES dbo.DimCustomers(CustomerKey);
go
 
ALTER TABLE dbo.FactCustomersAddresses ADD CONSTRAINT
	fkFactCustomersAddressesToDimAddresses FOREIGN KEY (AddressKey) 
	REFERENCES dbo.DimAddresses(AddressKey); 
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesOrderDateToDimDates FOREIGN KEY (OrderDateKey) 
	REFERENCES dbo.DimDates(CalendarDateKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesDueDateToDimDates FOREIGN KEY (DueDateKey) 
	REFERENCES dbo.DimDates(CalendarDateKey	);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesShipDateDimDates FOREIGN KEY (ShipDateKey)
	REFERENCES dbo.DimDates (CalendarDateKey);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesShiptoToDimAddresses FOREIGN KEY (	ShipToAddressKey)
	REFERENCES dbo.DimAddresses (AddressKey	);
go

ALTER TABLE dbo.FactSales ADD CONSTRAINT
	fkFactSalesBilltoToDimAddresses FOREIGN KEY (BillToAddressKey)
	REFERENCES dbo.DimAddresses (AddressKey	);
go

ALTER TABLE dbo.DimProductCategories ADD CONSTRAINT
	fkDimProductCategoriesParentToDimProductCategories FOREIGN KEY (ParentProductCategoryKey)
	REFERENCES dbo.DimProductCategories	(ProductCategoryKey);
go


Select 'That database was created';