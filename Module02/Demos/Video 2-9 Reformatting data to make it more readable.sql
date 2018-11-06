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



'Cleansing data values or making them more readable'
---------------------------------------------------------------------------------------------------------------------
  -- 1) Look at the Source table's Metadata 
EXECUTE [AdventureWorksLT2012].dbo.pSelMetaDataByTableName 
  @TableName = 'ProductCategory'
;
go

-- 2) Look the Source's data
SELECT
  [ProductCategoryID]
, [ParentProductCategoryID]
, [Name]
FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory]
go

-- 3) Make a Destination test table
Use TempDB;
go
If (object_id('TestDimProductCategories') is not null) Drop Table TestDimProductCategories;
go
CREATE
TABLE TestDimProductCategories
( [ProductCategoryKey] int Not Null Primary Key Identity(100,100) -- Added a Surrogate Key
, [ProductCategoryID] int Not Null
, [ProductCategoryName] nvarchar(50) Not Null
, [ParentProductCategoryID] int Not Null
, [ParentProductCategoryName] nvarchar(50) Not Null
);
go

-- 4) Create and Test some ETL processing code
INSERT INTO [TempDB].[dbo].[TestDimProductCategories]
( [ProductCategoryID]
, [ProductCategoryName]
, [ParentProductCategoryID]
, [ParentProductCategoryName]
)
SELECT
  [ProductCategoryID] = T1.[ProductCategoryID]
, [ProductCategoryName] = T1.[Name]
, [ParentProductCategoryID] = T1.[ParentProductCategoryID] 
, [ParentProductCategoryName] = T2.Name
FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T1
JOIN [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T2
  ON T1.ParentProductCategoryID = T2.ProductCategoryID 
;
go

-- 5) Verify that it worked!
Select * From  [TempDB].[dbo].[TestDimProductCategories]
;
go