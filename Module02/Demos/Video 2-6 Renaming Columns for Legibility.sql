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


'Renaming columns for legibility'
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
FROM [AdventureWorksLT2012].[SalesLT].[Customer]
;
go

-- 3) Make a Destination test table
Use TempDB;
go
If (object_id('TestDimCustomers') is not null) Drop Table TestDimCustomers;
go
CREATE
TABLE TestDimCustomers
( [CustomerID] int Not Null
, [ContactFirstName] nvarchar(50) Not Null 
, [ContactLastName] nvarchar(50) Not Null 
, [CompanyName] nvarchar(128) Not Null
, [SalesPersonAlias] nvarchar(256) Not Null
);
go

-- 4) Create and Test some ETL processing code
INSERT INTO [TempDB].[dbo].[TestDimCustomers]
( [CustomerID]
, [ContactFirstName]
, [ContactLastName] 
, [CompanyName]
, [SalesPersonAlias]
)
SELECT 
  [CustomerID] = [CustomerID]
, [ContactFirstName] = [FirstName]
, [ContactLastName] = [LastName]
, [CompanyName] = [CompanyName]
, [SalesPerson] AS [SalesPersonAlias] -- Optional Syntax 
FROM [AdventureWorksLT2012].[SalesLT].[Customer]
;
go

-- 5) Verify that it worked!
SELECT * FROM  [TempDB].[dbo].[TestDimCustomers];