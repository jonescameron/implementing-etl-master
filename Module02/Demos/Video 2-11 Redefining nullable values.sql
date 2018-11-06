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




'Redefining nullable values'
---------------------------------------------------------------------------------------------------------------------
  -- 1) Look at the Source table's Metadata 
EXECUTE [AdventureWorksLT2012].dbo.pSelMetaDataByTableName 
  @TableName = 'Product'
;
go

-- 2) Look the Source's data
SELECT 
  [ProductID]
, [Name]
, [Color]
, [Size]
, [SellStartDate]
, [SellEndDate]
, [ProductCategoryID]
FROM [AdventureWorksLT2012].[SalesLT].[Product]
go

SELECT 
  [ProductCategoryID]
, [ParentProductCategoryID]
, [Name]
FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory]
go

-- 3) Make a Destination test table
USE TempDB;
go
If (object_id('TestDimProducts') is not null) Drop Table TestDimProducts;
go
CREATE 
TABLE [dbo].[TestDimProducts]
( [ProductID] [int]  NOT NULL Primary Key
, [ProductName]  nvarchar(50) NOT NULL
, [ProductColor] nvarchar(50) NOT NULL -- Changed This to Not Null
, [ProductSize] nvarchar(50) NOT NULL -- Changed This to Not Null
, [ProductSellingStartDate] date NOT NULL -- Added this
, [ProductSellingEndDate] date NOT NULL -- Added this
, [ProductCategoryID] int Not Null
, [ProductCategoryName] nvarchar(50) Not Null
, [ParentProductCategoryName] nvarchar(50) Not Null
)
;

-- 4) Create and Test some ETL processing code
INSERT INTO [dbo].[TestDimProducts]
( [ProductID]
, [ProductName]
, [ProductColor]
, [ProductSize]
, [ProductSellingStartDate]
, [ProductSellingEndDate]
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

, [ProductSellingStartDate] = Cast( T3.SellStartDate as date)
, [ProductSellingEndDate] = IsNull( (Cast (T3.SellEndDate as date) ),'9999-12-31')
--------
, [ProductCategoryID] = T1.[ProductCategoryID]
, [ProductCategoryName] = T1.[Name]
, [ParentProductCategoryName] = T2.Name
FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
  ON T1.ParentProductCategoryID = T2.ProductCategoryID 
JOIN [AdventureWorksLT2012].[SalesLT].[Product] as T3
  ON T1.ProductCategoryID = T3.ProductCategoryID
;
go

-- 5) Verify that it worked!
Select * From  [TempDB].[dbo].[TestDimProducts]
;
go



--********************************************************************--
-- OPTIONAL: Create the ETL Lookup objects
--********************************************************************--

-- 1) Create a Null Lookup table
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

-- 2) Fill Null Lookup Table
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


-- 3) Make a Destination test table
USE TempDB;
go
If (object_id('TestDimProducts') is not null) Drop Table TestDimProducts;
go
CREATE 
TABLE [dbo].[TestDimProducts]
( [ProductID] [int]  NOT NULL Primary Key
, [ProductName]  nvarchar(50) NOT NULL
, [ProductColor] nvarchar(50) NOT NULL
, [ProductSize] nvarchar(50) NOT NULL
, [ProductSellingStartDate] date NOT NULL
, [ProductSellingEndDate] date NOT NULL 
, [ProductSellingEndDateText] nvarchar(50) NOT NULL -- Added this
, [ProductCategoryID] int Not Null
, [ProductCategoryName] nvarchar(50) Not Null
, [ParentProductCategoryName] nvarchar(50) Not Null
)
;

-- 4) Create and Test some ETL processing code
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

-- 5) Verify that it worked!
Select * From  [TempDB].[dbo].[TestDimProducts]
;
go

