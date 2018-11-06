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



'Converting data types for consistency'
---------------------------------------------------------------------------------------------------------------------
  -- 1) Look at the Source table's Metadata 
EXECUTE [AdventureWorksLT2012].dbo.pSelMetaDataByTableName 
  @TableName = 'Customer'
;
go

-- 2) Look the Source's data
SELECT 
  [CustomerID]
, [FirstName]
, [LastName]
, [CompanyName]
, [SalesPerson]
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

-- 3) Make a Destination test table
Use TempDB;
go
If (object_id('TestDimCustomers') is not null) Drop Table TestDimCustomers;
go

CREATE
TABLE TestDimCustomers
( [CustomerID] int Not Null Primary Key
, [ContactFullName] nvarchar(200) Not Null -- Combined data
, [CompanyName] nvarchar(200) Not Null
, [SalesPersonAlias] nvarchar(200) Not Null -- Split data
);
go

-- 4) Create and Test some ETL processing code
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

-- 5) Verify that it worked!
Select * From  [TempDB].[dbo].[TestDimCustomers]
;
go
