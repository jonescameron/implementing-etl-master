/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Demonstration Video 1-02: ETL with SQL Programming
USE DWAdventureWorksLT2012;
go

-- Original source data
SELECT 
  [CustomerID] --
, [NameStyle]
, [Title]
, [FirstName] --
, [MiddleName]
, [LastName] --
, [Suffix]
, [CompanyName]
, [SalesPerson]
, [EmailAddress]
, [Phone]
, [PasswordHash]
, [PasswordSalt]
, [rowguid]
, [ModifiedDate]
FROM [AdventureWorksLT2012].[SalesLT].[Customer]
ORDER BY CompanyName
go

-- Examine the properties of the source data
USE [AdventureWorksLT2012];
go
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
WHERE C.TABLE_NAME in ('Customer')
Order by C.TABLE_SCHEMA, C.TABLE_NAME, C.ORDINAL_POSITION
Go


-- Transformed data with SQL Code
USE DWAdventureWorksLT2012;
go
--- 1) Select the data you want to use
SELECT 
	  [CustomerID]
	, CompanyName 
	, [FirstName] 
	, [LastName]
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

--- 2) Use SQL code to perform transformation where possible
SELECT 
  [CustomerID]
, [CompanyName] = Cast(CompanyName as nvarchar(200))
, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

--- 3) Use SQL code to load the data into the reporting structures
INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
SELECT 
	  [CustomerID]
	, [CompanyName] = Cast(CompanyName as nvarchar(200))
	, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

















---Demonstration Video 1-03: Using SSMS to create ETL processing objects


-- Using standard SQL code for ETL processing
INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
SELECT 
	  [CustomerID]
	, [CompanyName] = Cast(CompanyName as nvarchar(200))
	, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go


-- Transformation Code contained in a View
CREATE VIEW vETLDimCustomersData
AS
	SELECT 
		  [CustomerID]
		, [CompanyName] = Cast(CompanyName as nvarchar(200))
		, [ContactFullName] = [FirstName] + ' ' + [LastName]
	FROM [AdventureWorksLT2012].[SalesLT].[Customer];
go

-- Transformation View used for Loading 
INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
SELECT 
  [CustomerID]
, [CompanyName]
, [ContactFullName]
FROM [DWAdventureWorksLT2012].[dbo].[vETLDimCustomersData];


-- Transformation View used for Loading via a Stored Procedure
CREATE -- Fill Dim Customers Procedure
PROCEDURE pETLFillDimCustomers
AS
	/**************************************************************
	Desc: Fills the DimCustomers dimension table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillDimCustomers'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
	SELECT 
	  [CustomerID]
	, [CompanyName]
	, [ContactFullName]
	FROM [DWAdventureWorksLT2012].[dbo].[vETLDimCustomersData];
	  
  -- ETL Code  -------------------------------------------------------------------
  Commit Transaction;
  Select @EventStatus = 'Success', @EventErrorInfo = 'NA';
  Set @RC = 100; -- Success
 End Try
 Begin Catch
  Rollback Tran;
  Select @EventStatus = 'Failure';
  -- select and format information about any error (JSON)-- 
  Execute pSelErrorInfo @ErrorInfo = @EventErrorInfo output;
  ---------------------------------------------------------------------------------------------
  Set @RC = -100; -- Failure
 End Catch
   -- Logging Code  -------------------------------------------------------------------
	  Execute pInsETLEvents
			@ETLEventName =  @EventName
		  , @ETLEventStatus = @EventStatus
		  , @ETLEventErrorInfo = @EventErrorInfo
		  ;  
  -- Logging Code  -------------------------------------------------------------------
  -- Now insert it into the ETLEvents table  
 Return @RC;
End -- Procedure Code
;
go


























--********************************************************************--
-- Clear Table Data
--********************************************************************--
CREATE -- Clear Table Data Procedure
PROCEDURE pETLClearTableData
AS
	/**************************************************************
	Desc: This procedure truncates data from all tables 
	  except DimDates
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	@RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLClearTableData Executed'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	TRUNCATE TABLE dbo.FactSales;
	TRUNCATE TABLE dbo.FactCustomersAddresses;
	TRUNCATE TABLE dbo.DimProductCategories;
	TRUNCATE TABLE dbo.DimProducts; 
  
  -- ETL Code  -------------------------------------------------------------------
  Commit Transaction;
  Select @EventStatus = 'Success', @EventErrorInfo = 'NA';
  Set @RC = 100; -- Success
 End Try
 Begin Catch
  Rollback Tran;
  Select @EventStatus = 'Failure';
  -- select and format information about any error (JSON)-- 
  Execute pSelErrorInfo @ErrorInfo = @EventErrorInfo output;
  ---------------------------------------------------------------------------------------------
  Set @RC = -100; -- Failure
 End Catch
   -- Logging Code  -------------------------------------------------------------------
	  Execute pInsETLEvents
			@ETLEventName =  @EventName
		  , @ETLEventStatus = @EventStatus
		  , @ETLEventErrorInfo = @EventErrorInfo
		  ;  
  -- Logging Code  -------------------------------------------------------------------
  -- Now insert it into the ETLEvents table  
 Return @RC;
End -- Procedure Code
;
go







-- ETL Functions --

-- There are many built in SQL functions, handy for ETL processing
Select 
 [Yesterday] = DATEADD(dd,-1,Getdate())
,[Today] = GetDate();
go

-- You can also create your own custom User Defined Functions (UDFs) 
CREATE FUNCTION [dbo].fSelNullDescription
(@NullTypeID int = 0)  
ReturnS nvarchar(1000)   
AS   
 Begin -- Function
  Declare @Desc nvarchar(1000);  
  Select @Desc = Case @NullTypeID
   When - 1 Then 'Unknown: Value is currently unknown, but should be available later'
   When - 2 Then 'Unavaliable: Value is currently unknown and is unlikely to be available later'
   When - 3 Then 'Corrupt: Original value appeared corrupt or suspicious. As such it was removed from the reporting data'
   When - 4 Then 'Not Defined: A value could be entered, but the source data has not yet defined it'
   Else 'Null: This Null Value Code has not be set OR perhaps you forgot to include a Null Type ID?'
   End -- Case
   Return @Desc;  
 End; -- Function
go

-- Now lets test the UDF
Select [Null Status and Description] = [dbo].fSelNullDescription (-1)
Select [Null Status and Description] = [dbo].fSelNullDescription (-3)
Select [Null Status and Description] = [dbo].fSelNullDescription (123)









-- You can use this within your Views or Stored Procedures
CREATE VIEW vETLDimCustomersTodaysData
AS
	SELECT 
		  [CustomerID]
		, [CompanyName] = Cast(CompanyName as nvarchar(200))
		, [ContactFullName] = [FirstName] + ' ' + [LastName]
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	WHERE [ModifiedDate] > DATEADD(dd,-1,Getdate());
go


-- However, Views cannot use parameters! (Stored Procedures can.)
CREATE VIEW vETLDimCustomersDataByDateRange
( @MinModifiedDate datetime)
AS
	SELECT 
		  [CustomerID]
		, [CompanyName] = Cast(CompanyName as nvarchar(200))
		, [ContactFullName] = [FirstName] + ' ' + [LastName]
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	WHERE [ModifiedDate] > @MinModifiedDate;
go

-- Custom User Defined Functions (UDFs) can use parameters! 
CREATE FUNCTION fETLDimCustomersData
( @MinModifiedDate datetime)
Returns Table
AS
 Return(
	SELECT 
		  [CustomerID]
		, [CompanyName] = Cast(CompanyName as nvarchar(200))
		, [ContactFullName] = [FirstName] + ' ' + [LastName]
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	WHERE [ModifiedDate] > @MinModifiedDate
	);
go


-- You may use a UDF like this...
Declare @IncrementalLoadStartDate datetime = DateDiff(dd,-7,GetDate());

-- INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
SELECT 
	  [CustomerID]
	, [CompanyName]
	, [ContactFullName]
FROM [DWAdventureWorksLT2012].[dbo].[fETLDimCustomersData](@IncrementalLoadStartDate);
Go



-- A Similar Stored Procedure
CREATE Procedure pETLDimCustomersDataIncremental
( @MinModifiedDate datetime)
AS
  BEGIN
	SELECT 
	  [CustomerID]
	, [CompanyName] = Cast(CompanyName as nvarchar(200))
	, [ContactFullName] = [FirstName] + ' ' + [LastName]
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	WHERE [ModifiedDate] > @MinModifiedDate;
 END
go

-- You may use a Store Procedure like this...
Declare @IncrementalLoadStartDate datetime = DateDiff(dd,-7,GetDate());

-- INSERT INTO [DWAdventureWorksLT2012].[dbo].[DimCustomers]
 Execute pETLDimCustomersDataIncremental 
   @MinModifiedDate = @IncrementalLoadStartDate;
Go




















CREATE -- Error Handling Info
PROCEDURE pSelErrorInfo
( @ErrorInfo nvarchar(1000) output)
AS
 Begin -- Procedure
    SELECT @ErrorInfo = 
       '{ "ErrorNumber" : "' +  Cast(ERROR_NUMBER() as varchar(50))
    + '", "ErrorSeverity" : "' + Cast(ERROR_SEVERITY() as varchar(50))        
    + '", "ErrorState" : "' + Cast(ERROR_STATE() as varchar(50))     
    + '", "ErrorProcedure" : "' + IsNull(ERROR_PROCEDURE(), 'NA')   
    + '", "ErrorLine" : "' + Cast(ERROR_LINE() as varchar(50))    
    + '", "ErrorMessage" : "'  + ERROR_MESSAGE()
	+ '" }' ;  
 End -- Procedure
 ;
go


