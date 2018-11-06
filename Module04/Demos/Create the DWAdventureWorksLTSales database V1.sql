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
--  Create a Null Lookup table:
CREATE -- Lookup Null Statuses
TABLE ETLNullStatuses	
( NullStatusID int Not Null  
, NullStatusDateKey date -- date = YYYY-MM-DD between 0001-01-01 through 9999-12-31
, NullStatusName nvarchar (50)
, NullStatusDescription nvarchar (1000)
CONSTRAINT [pkETLNullStatuses]  PRIMARY KEY Clustered (NullStatusID desc)
);
go

--  Fill Null Lookup Table
INSERT -- Lookup data
INTO [DWAdventureWorksLT2012v1].[dbo].[ETLNullStatuses]
( NullStatusID
, NullStatusDateKey
, NullStatusName
, NullStatusDescription
) 
VALUES
	  (-1,'9999-12-31','Unavaliable', 'Value is currently unknown, but should be available later')
	, (-2,'0001-01-01','Not Applicable', 'A value is not applicable to this item')
	, (-3,'0001-01-02','Unknown', 'Value is currently unknown, but may be available later')
	, (-4,'0001-01-03','Corrupt', 'Original value appeared corrupt or suspicious. As such it was removed from the reporting data')
	, (-5,'0001-01-04','Not Defined', 'A value could be entered, but the source data has not yet defined it')
;
go

-- Create Date Dimension Lookup Table:
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

-- Fill DimDates Lookup Table
-- Step a: Declare variables use in processing
SET NOCOUNT ON;
Declare @StartDate date; 
Declare @EndDate date;

-- Step b:  Fill the variable with values for the range of years needed
Select @StartDate = '01-01-' + Cast(Year(Min([OrderDate])) as nvarchar(50))
	From [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader]; 
Select @EndDate = '12-31-' + Cast(Year(Max([OrderDate]))  as nvarchar(50))
	From [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader];

-- Step c:  Use a while loop to add dates to the table
Declare @DateInProcess datetime = @StartDate;

While @DateInProcess <= @EndDate
	Begin
	--Add a row into the date dimension table for this date
		Insert Into [DWAdventureWorksLT2012v1].[dbo].[DimDates] 
		( [CalendarDateKey]
		, [CalendarDateName]
		, [CalendarYearMonthID]
		, [CalendarYearMonthName]
		, [CalendarYearQuarterID]
		, [CalendarYearQuarterName]
		, [CalendarYearID]
		, [CalendarYearName]
		, [CalendarDate]
		, [FiscalDate]
		)
		Values ( 
		  Convert(nvarchar(50), @DateInProcess, 112) -- [CalendarDateKey]
		, DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess, 110) --  [CalendarDateName]
		, Left(Convert(nvarchar(50), @DateInProcess, 112), 6) -- [CalendarYearMonthKey]
		, DateName( month, @DateInProcess ) -- [CalendarYearMonthName]
		, Cast( Year(@DateInProcess) as nVarchar(50)) + '0' + DateName( quarter, @DateInProcess)   --[CalendarYearQuarterKey]
		, 'Q' + DateName( quarter, @DateInProcess ) + ' - ' + Cast( Year(@DateInProcess) as nVarchar(50)) --[CalendarYearQuarterName]
		, Year( @DateInProcess ) -- [CalendarYearKey] 
		, Cast( Year( @DateInProcess) as nVarchar(50) ) -- [CalendarYearName]
		, Convert([Date], @DateInProcess) 	-- [FiscalDateKey] 			   
		, Convert([Date], DateAdd(mm,-6,@DateInProcess)) 	-- [FiscalDateKey] 
		);  
		-- Add a day and loop again
		Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	End
SET NOCOUNT ON;
go

-- Create Other Dimension Tables:
CREATE 
TABLE [dbo].[DimProducts]
( ProductKey int NOT NULL Primary Key IDENTITY(1, 1)
, [ProductID] [int]  NOT NULL
, [ProductName]  nvarchar(50) NOT NULL
, [ProductColor] nvarchar(50) NOT NULL
, [ProductSize] nvarchar(50) NOT NULL
, [ProductSellingStartDate] date NOT NULL
, [ProductSellingEndDate] date NOT NULL 
, [ProductSellingEndDateText] nvarchar(50) NOT NULL
, [ProductCategoryID] int Not Null
, [ProductCategoryName] nvarchar(50) Not Null
, [ParentProductCategoryName] nvarchar(50) Not Null
)
;

If (object_id('DimCustomers') is not null) Drop Table DimCustomers;
go

CREATE
TABLE DimCustomers
( CustomerKey int NOT NULL Primary Key IDENTITY(1, 1)
, [CustomerID] int Not Null 
, [ContactFullName] nvarchar(200) Not Null
, [CompanyName] nvarchar(200) Not Null
, [SalesPersonAlias] nvarchar(200) Not Null
);
go

-- Create Fact Tables:
If (object_id('FactSales') is not null) Drop Table FactSales;
go
CREATE TABLE [dbo].[FactSales]
( [SalesOrderID] [int] NOT NULL
, [SalesOrderDetailID] [int] NOT NULL
, [OrderDateKey] [int] NOT NULL
, [ShipDateKey] [int] NOT NULL
, [CustomerKey] [int] NOT NULL
, [ProductKey] [int] NOT NULL
, [OrderQty] [smallint] NOT NULL
, [UnitPrice] [money] NOT NULL
, [UnitPriceDiscount] [money] NOT NULL
	CONSTRAINT [pk FactSales] PRIMARY KEY
	( [SalesOrderID]
	, [SalesOrderDetailID]
	, [OrderDateKey]
	, [ShipDateKey] 
	, [CustomerKey]
	, [ProductKey]
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


--********************************************************************--
-- Create the ETL Views
--********************************************************************--
Create View vETLDimProducts
AS
	SELECT 
	  [ProductID] = T3.[ProductID]
	, [ProductName] = Cast( T3.[Name] as nvarchar(50))
	, [ProductColor] = Cast( ( CASE  
		When ( (T3.[Color] is Null) AND (T2.Name = 'Components') ) Then 'Per Bike'
		When ( (T3.[Color] is Null) AND (T2.Name = 'Accessories') ) Then 'Per Material'
		Else T3.[Color] 
		End) as nvarchar(50))
	, [ProductSize] = Cast( IIF(T3.[Size] is Null, 'One Size Only', T3.[Size])  as nvarchar(50))
	, [ProductSellingStartDate] = T3.SellStartDate
	, [ProductSellingEndDate] =  IsNull( T3.SellEndDate ,'9999-12-31')
	, [ProductSellingEndDateText] = IsNull(T4.NullStatusName, T3.SellEndDate) 
	, [ProductCategoryID] = T1.[ProductCategoryID]
	, [ProductCategoryName] = T1.[Name]
	, [ParentProductCategoryName] = T2.Name
	FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T1
	JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
	  ON T1.ParentProductCategoryID = T2.ProductCategoryID 
	JOIN [AdventureWorksLT2012].[SalesLT].[Product] as T3
	  ON T1.ProductCategoryID = T3.ProductCategoryID
	Left JOIN [DWAdventureWorksLT2012v1].[dbo].[ETLNullStatuses] as T4
	 ON  IsNull( T3.SellEndDate ,'9999-12-31') = T4.NullStatusDateKey
	;
go

CREATE VIEW vETLDimCustomers
AS
	SELECT 
	  [CustomerID] = [CustomerID]
	, [ContactFullName] = Convert( nvarchar(200), [FirstName] + ' ' + [LastName])
	, [CompanyName] = Cast( [CompanyName] AS nvarchar(200) )
	, [SalesPersonAlias] = Cast( Substring( [SalesPerson], PatIndex( '%\%',[SalesPerson] ) + 1, 256 ) AS nvarchar(200) )
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	;
go

CREATE VIEW vETLFactSales
AS
	SELECT 
	  SalesOrderID = T2.SalesOrderID
	, SalesOrderDetailID = T1.SalesOrderDetailID
	, OrderDateKey = T6.CalendarDateKey
	, ShipDateKey = T5.CalendarDateKey
	, CustomerKey = T4.CustomerKey
	, ProductKey = T3.ProductKey
	, OrderQty = T1.OrderQty
	, UnitPrice = T1.UnitPrice
	, UnitPriceDiscount = T1.UnitPriceDiscount
	FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
	JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
	  ON T1.SalesOrderID = T2.SalesOrderID
	JOIN DWAdventureWorksLT2012v1.dbo.DimProducts as T3
	 ON T1.ProductID = T3.ProductID
	JOIN DWAdventureWorksLT2012v1.dbo.DimCustomers as T4
	 ON T2.CustomerID = T4.CustomerID
	JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T5
	 ON Cast(T2.ShipDate as date) = Cast(T5.CalendarDate as date)
	JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T6
	 ON Cast(T2.OrderDate as date) = Cast(T6.CalendarDate as date)
	;
go


--********************************************************************--
-- Create the ETL Stored Procedures
--********************************************************************--

-- DimProducts ETL processing code --
CREATE  
PROCEDURE pETLDimProducts
AS
	/**************************************************************
	Desc: <Desc Goes Here>
	ChangeLog: When, Who, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
 Declare 
   @RC int = 0;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------
	  INSERT INTO [dbo].[DimProducts]
	( [ProductID]
	, [ProductName]
	, [ProductColor]
	, [ProductSize]
	, [ProductSellingStartDate]
	, [ProductSellingEndDate]
	, [ProductSellingEndDateText] 
	, [ProductCategoryID]
	, [ProductCategoryName]
	, [ParentProductCategoryName]
	)
	SELECT 
	  [ProductID] 
	, [ProductName] 
	, [ProductColor] 
	, [ProductSize] 
	, [ProductSellingStartDate] 
	, [ProductSellingEndDate] 
	, [ProductSellingEndDateText]
	, [ProductCategoryID] 
	, [ProductCategoryName] 
	, [ParentProductCategoryName]
	FROM DWAdventureWorksLT2012v1.dbo.vETLDimProducts
	;
   -- ETL Code  -------------------------------------------------------------------
  Commit Transaction;
  Set @RC = 100; -- Success
 End Try
 Begin Catch
  Rollback Tran;
  Set @RC = -100; -- Failure
 End Catch
 Return @RC;
End -- Procedure Code
;
go

-- DimCustomers ETL processing code -- 
CREATE 
PROCEDURE pETLDimCustomers
AS
	/**************************************************************
	Desc: <Desc Goes Here>
	ChangeLog: When, Who, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
 Declare 
   @RC int = 0;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------
	INSERT INTO [DWAdventureWorksLT2012v1].[dbo].[DimCustomers]
	( [CustomerID]
	, [ContactFullName]
	, [CompanyName]
	, [SalesPersonAlias]
	)
	SELECT 
	  [CustomerID]
	, [ContactFullName]
	, [CompanyName]
	, [SalesPersonAlias]
	FROM DWAdventureWorksLT2012v1.dbo.vETLDimCustomers
	;  
  -- ETL Code  -------------------------------------------------------------------
  Commit Transaction;
  Set @RC = 100; -- Success
 End Try
 Begin Catch
  Rollback Tran;
  Set @RC = -100; -- Failure
 End Catch
 Return @RC;
End -- Procedure Code
;
go

-- FactSales ETL processing code -- 
CREATE
PROCEDURE pETLFactSales
AS
	/**************************************************************
	Desc: <Desc Goes Here>
	ChangeLog: When, Who, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
 Declare 
   @RC int = 0;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------
  	  INSERT INTO [dbo].[FactSales]
	( [SalesOrderID]
	, [SalesOrderDetailID]
	, [OrderDateKey]
	, [ShipDateKey]
	, [CustomerKey] 
	, [ProductKey] 
	, [OrderQty]
	, [UnitPrice]
	, [UnitPriceDiscount]
	) 
	SELECT 
	  SalesOrderID
	, SalesOrderDetailID
	, OrderDateKey
	, ShipDateKey
	, CustomerKey
	, ProductKey
	, OrderQty
	, UnitPrice
	, UnitPriceDiscount
	FROM DWAdventureWorksLT2012v1.dbo.vETLFactSales
	; 
  -- ETL Code  -------------------------------------------------------------------
  Commit Transaction;
  Set @RC = 100; -- Success
 End Try
 Begin Catch
  Rollback Tran;
  Set @RC = -100; -- Failure
 End Catch
 Return @RC;
End -- Procedure Code
;
go 

Select 'Version 1 of the database was created';