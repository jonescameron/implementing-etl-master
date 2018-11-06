/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- ( Transformations Demo )--

'Demo Setup Code '
---------------------------------------------------------------------------------------------------------------------
USE [AdventureWorksLT2012];
go
If (object_id('pSelMetaDataByTableName') is not null) Drop Procedure pSelMetaDataByTableName;
go
CREATE PROCEDURE [pSelMetaDataByTableName]
( @TableName nvarchar(200))
AS
 BEGIN -- procedure code
	SELECT
	  [ColumnFullName] = C.TABLE_SCHEMA  + '.' +  C.TABLE_NAME  + '.' + COLUMN_NAME
	, DataType = Case 
	  When DATA_TYPE in ( 'Money', 'Decimal') 
		Then IsNull(DATA_TYPE,'') 
		+ ' (' +  Cast(NUMERIC_PRECISION as nvarchar(50)) 
		+  ',' +  Cast(NUMERIC_SCALE as nvarchar(50)) 
		+ ' )'
	  When DATA_TYPE in ('bit', 'int', 'tinyint','bigint', 'datetime', 'uniqueidentifier') 
		Then IsNull(DATA_TYPE,'') 
	  Else  IsNull(DATA_TYPE,'') + ' (' +  Cast(IsNull(CHARACTER_MAXIMUM_LENGTH,'') as nvarchar(50)) + ')'
	  End
	, IsNullable = IsNull(IS_NULLABLE,'')
	--, ORDINAL_POSITION
	--, COLUMN_DEFAULT = IsNull(COLUMN_DEFAULT,'')
	FROM [INFORMATION_SCHEMA].[COLUMNS] as C
	JOIN [INFORMATION_SCHEMA].[TABLES] as T
	  ON C.TABLE_NAME = T.TABLE_NAME
	WHERE C.TABLE_NAME in (@TableName)
	Order by C.TABLE_SCHEMA, C.TABLE_NAME, C.ORDINAL_POSITION
 END -- procedure code
go

USE TempDB;
go
If (object_id('TestDimDates') is not null) Drop Table TestDimDates;
go

CREATE -- Dates Dimension  
TABLE TestDimDates	
( CalendarDateKey int Not Null CONSTRAINT [pkTestDimDates] PRIMARY KEY
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
		Insert Into [TempDB].[dbo].[TestDimDates] 
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
go

--  Create a Null Lookup table
USE TempDB;
go
If (object_id('ETLNullStatuses') is not null) Drop Table ETLNullStatuses;
go
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
INTO [TempDB].[dbo].[ETLNullStatuses]
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
-- SELECT * FROM  [TempDB].[dbo].[ETLNullStatuses]


-- Make a Destination test table
USE TempDB;
go
If (object_id('TestDimProducts') is not null) Drop Table TestDimProducts;
go
CREATE 
TABLE [dbo].[TestDimProducts]
( ProductKey int NOT NULL Primary Key IDENTITY(1, 1) -- Added this!
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

--  Create and Test some ETL processing code
INSERT INTO [dbo].[TestDimProducts]
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
  [ProductID] = T3.[ProductID]
, [ProductName] = Cast( T3.[Name] as nvarchar(50))
--------
, [ProductColor] = Cast( ( CASE  
	When ( (T3.[Color] is Null) AND (T2.Name = 'Components') ) Then 'Per Bike'
	When ( (T3.[Color] is Null) AND (T2.Name = 'Accessories') ) Then 'Per Material'
	Else T3.[Color] 
	End) as nvarchar(50))

, [ProductSize] = Cast( IIF(T3.[Size] is Null, 'One Size Only', T3.[Size])  as nvarchar(50))

, [ProductSellingStartDate] = T3.SellStartDate
, [ProductSellingEndDate] =  IsNull( T3.SellEndDate ,'9999-12-31')

, [ProductSellingEndDateText] = IsNull(T4.NullStatusName, T3.SellEndDate) 

--------
, [ProductCategoryID] = T1.[ProductCategoryID]
, [ProductCategoryName] = T1.[Name]
, [ParentProductCategoryName] = T2.Name
FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
  ON T1.ParentProductCategoryID = T2.ProductCategoryID 
JOIN [AdventureWorksLT2012].[SalesLT].[Product] as T3
  ON T1.ProductCategoryID = T3.ProductCategoryID
Left JOIN [TempDB].[dbo].[ETLNullStatuses] as T4
 ON  IsNull( T3.SellEndDate ,'9999-12-31') = T4.NullStatusDateKey
;
go


-- Make a Destination test table
USE TempDB;
go

If (object_id('TestDimCustomers') is not null) Drop Table TestDimCustomers;
go

CREATE
TABLE TestDimCustomers
( CustomerKey int NOT NULL Primary Key IDENTITY(1, 1) -- Added this!
, [CustomerID] int Not Null 
, [ContactFullName] nvarchar(200) Not Null -- Combined data
, [CompanyName] nvarchar(200) Not Null
, [SalesPersonAlias] nvarchar(200) Not Null -- Split data
);
go

--  Create and Test some ETL processing code
INSERT INTO [TempDB].[dbo].[TestDimCustomers]
( [CustomerID]
, [ContactFullName]
, [CompanyName]
, [SalesPersonAlias]
)
SELECT 
  [CustomerID] = [CustomerID]
, [ContactFirstName] = Convert( nvarchar(200), [FirstName] + ' ' + [LastName])
, [CompanyName] = Cast( [CompanyName] AS nvarchar(200) )
, [SalesPersonAlias] = Cast( Substring( [SalesPerson], PatIndex( '%\%',[SalesPerson] ) + 1, 256 ) AS nvarchar(200) )
FROM [AdventureWorksLT2012].[SalesLT].[Customer]
;
go

--  Verify that it worked!
Select * From  [TempDB].[dbo].[TestDimDates];
Select * From  [TempDB].[dbo].[TestDimProducts];
Select * From  [TempDB].[dbo].[TestDimCustomers];
go


'Connecting Foreign Keys to Surrogate Keys'
---------------------------------------------------------------------------------------------------------------------
-- 1) Look at the Source table's Metadata 
EXECUTE [AdventureWorksLT2012].dbo.pSelMetaDataByTableName 
  @TableName = 'SalesOrderHeader'
;

EXECUTE [AdventureWorksLT2012].dbo.pSelMetaDataByTableName 
  @TableName = 'SalesOrderDetail'
;
go

-- 2) Look the Source's data
SELECT 
  T2.SalesOrderID
, T1.SalesOrderDetailID
, T2.OrderDate
, T2.ShipDate
, T2.CustomerID
, T1.ProductID
, T1.OrderQty
, T1.UnitPrice
, T1.UnitPriceDiscount
FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
INNER JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
  ON T1.SalesOrderID = T2.SalesOrderID


-- 3) Make a Destination test tables
Use TempDB;
go

If (object_id('TestFactSales') is not null) Drop Table TestFactSales;
go
CREATE TABLE [dbo].[TestFactSales]
( [SalesOrderID] [int] NOT NULL
, [SalesOrderDetailID] [int] NOT NULL
, [OrderDateKey] [int] NOT NULL
, [ShipDateKey] [int] NOT NULL
, [CustomerKey] [int] NOT NULL
, [ProductKey] [int] NOT NULL
, [OrderQty] [smallint] NOT NULL
, [UnitPrice] [money] NOT NULL
, [UnitPriceDiscount] [money] NOT NULL
CONSTRAINT [pkTestFactSales] PRIMARY KEY
( [SalesOrderID]
, [SalesOrderDetailID]
, [OrderDateKey]
, [ShipDateKey] 
, [CustomerKey]
, [ProductKey]
) 
);

-- 4) Create and Test some ETL processing code
INSERT INTO [dbo].[TestFactSales]
( [SalesOrderID]
, [SalesOrderDetailID]
, [OrderDateKey] -- Surrogate Key
, [ShipDateKey] -- Surrogate Key
, [CustomerKey] -- Surrogate Key
, [ProductKey] -- Surrogate Key
, [OrderQty]
, [UnitPrice]
, [UnitPriceDiscount]
) 
SELECT 
  T2.SalesOrderID
, T1.SalesOrderDetailID
--, T2.OrderDate
, T6.CalendarDateKey
--, T2.ShipDate
, T5.CalendarDateKey
--, T2.CustomerID
, T4.CustomerKey
--, T1.ProductID
, T3.ProductKey
, T1.OrderQty
, T1.UnitPrice
, T1.UnitPriceDiscount
FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
  ON T1.SalesOrderID = T2.SalesOrderID
JOIN Tempdb.dbo.TestDimProducts as T3
 ON T1.ProductID = T3.ProductID
JOIN TempDB.dbo.TestDimCustomers as T4
 ON T2.CustomerID = T4.CustomerID
JOIN TempDB.dbo.TestDimDates as T5
 ON Cast(T2.ShipDate as date) = Cast(T5.CalendarDate as date)
JOIN TempDB.dbo.TestDimDates as T6
 ON Cast(T2.OrderDate as date) = Cast(T6.CalendarDate as date)
;
go

Select * from tempdb.dbo.TestFactSales;