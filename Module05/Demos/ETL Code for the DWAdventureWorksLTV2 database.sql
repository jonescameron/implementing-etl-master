/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

--****************** [ DWAdventureWorksLT2012V2 ETL Code Version 2] *********************--
-- This file will flush and fill the sales data mart in the DWAdventureWorksLT2012V2 database
--***********************************************************************************************--
Use DWAdventureWorksLT2012V2;
go

--********************************************************************--
-- Create the ETL Lookup objects
--********************************************************************--
If (object_id('ETLNullStatuses') is not null) Drop Table ETLNullStatuses;
go
CREATE -- Lookup Null Statuses
TABLE ETLNullStatuses	
( NullStatusID int Not Null  
, NullStatusName nvarchar (50)
, NullStatusDescription nvarchar (1000)
CONSTRAINT [pkETLNullStatuses]  PRIMARY KEY Clustered (NullStatusID desc)
);
go

If (object_id('ETLUSHolidays') is not null) Drop Table ETLUSHolidays;
go
CREATE -- Lookup US Holidays
TABLE ETLUSHolidays	
(USHolidayID int Not Null CONSTRAINT [pkETLUSHolidays] PRIMARY KEY 
,USHolidayName	nvarchar (200)
,WasCompanyHoliday bit
);
go

--********************************************************************--
-- Create the ETL Logging objects
--********************************************************************--
If (object_id('ETLEvents') is not null) Drop Table ETLEvents;
go
CREATE -- Logging Table
TABLE ETLEvents
( ETLEventID int Not Null CONSTRAINT [pkETLLog] PRIMARY KEY Identity(1,1)
, ETLEventName nvarchar(200) Not Null 
, ETLEventDateTime datetime Not Null Constraint dfCurrentDateTime Default (getdate())
, ETLEventStatus  nvarchar(50) Not Null
, ETLEventErrorInfo  nvarchar(1000) Not Null 
);
Go

If (object_id('pSelErrorInfo') is not null) Drop PROCEDURE pSelErrorInfo;
go
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

If (object_id('pInsETLEvents') is not null) Drop PROCEDURE pInsETLEvents;
go
CREATE -- Logging Insert Procedure
PROCEDURE pInsETLEvents
( @ETLEventName nvarchar(200) 
, @ETLEventStatus  nvarchar(50) 
, @ETLEventErrorInfo  nvarchar(1000) 
) AS
Begin -- Procedure
 Declare @RC int = 0;
 Begin Try
   Begin Transaction;
    Insert into ETLEvents 
	( ETLEventName
	, ETLEventStatus
	, ETLEventErrorInfo
	) Values 
   ( @ETLEventName
   , @ETLEventStatus
   , @ETLEventErrorInfo
   );
   Commit Transaction;
   Set @RC = 100; -- Success
 End Try
 Begin Catch
  -- Select and format information about any error
  Declare @ErrorInfo nvarchar(1000);
  Execute pSelErrorInfo @ErrorInfo = @ErrorInfo output;
  -- Write to the Windows Event Log for tech support/troubleshooting the Logging process
  RaisError(@ErrorInfo, 15, 1) With Log
  Rollback Transaction;
  Set @RC = -100; -- Failure
 End Catch
 Return @RC
End -- Procedure
;
go

--********************************************************************--
-- Fill Lookup Tables
--********************************************************************--
If (object_id('pETLFillNullLookupTable') is not null) Drop PROCEDURE pETLFillNullLookupTable;
go
CREATE -- Fill Null LookupTable Procedure
PROCEDURE pETLFillNullLookupTable
AS
	/**************************************************************
	Desc: Fills lookup table with null value descriptions
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillNullLookupTable'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	 -- Fill Null Lookup Table
	 INSERT -- Lookup data
	 INTO [DWAdventureWorksLT2012V2].[dbo].[ETLNullStatuses]
	 ( NullStatusID
	 , NullStatusName
	 , NullStatusDescription
	 ) 
	 VALUES
		   (-1,'Unknown', 'Value is currently unknown, but should be available later')
		 , (-2,'Not Applicable', 'A value is not really applicable to this item and is unlikely to be applied later')
		 , (-3,'Unavaliable', 'Value is currently unknown and is unlikely to be available later')
		 , (-4,'Corrupt', 'Original value appeared corrupt or suspicious. As such it was removed from the reporting data')
		 , (-5,'Not Defined', 'A value could be entered, but the source data has not yet defined it')
		;
  
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

If (object_id('pETLFillUSHolidaysLookupTable') is not null) Drop PROCEDURE pETLFillUSHolidaysLookupTable;
go
CREATE -- Fill US Holidays Lookup Table Procedure
PROCEDURE pETLFillUSHolidaysLookupTable
AS
	/**************************************************************
	Desc: Fills lookup table with null value descriptions
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillUSHolidaysLookupTable'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	 -- Fill Null Lookup Table
		INSERT -- Lookup data
		INTO [DWAdventureWorksLT2012V2].[dbo].[ETLUSHolidays]
		( USHolidayID
		, USHolidayName
		, WasCompanyHoliday
		)
		Values
		 ( 20040101,'Year''s Day', 1)
		,(20040119,'Martin Luther King Day', 1)
		,(20040216,	'Presidents'' Day', 1)
		,(20040531,'Memorial Day', 1)
		,(20040704,'Independence Day', 0)
		,(20040705,'Independence Day observed', 1)
		,(20040906,'Labor Day', 1)
		,(20041011,'Columbus Day', 0)
		,(20041111,'Veterans Day', 0)	
		,(20041125,'Thanksgiving Day', 1)	 
		,(20041224,'Christmas Day observed', 1)
		,(20041225,'Christmas Day', 0)
		,(20041231,'New Year''s Day observed', 1)

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

If (object_id('pETLFillDimDates') is not null) Drop PROCEDURE pETLFillDimDates;
go
CREATE -- Fill Dim Dates Procedure
PROCEDURE pETLFillDimDates
AS
	/**************************************************************
	Desc: Fills lookup table with null value descriptions
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillDimDates'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

		-- Step 1: Fill the table with dates data
		Declare @StartDate date; 
		Declare @EndDate date;

		-- Get the range of years needed
		Select @StartDate = '01-01-' + Cast(Year(Min([OrderDate])) as nvarchar(50))
			From [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader]; 
		Select @EndDate = '12-31-' + Cast(Year(Max([OrderDate]))  as nvarchar(50))
			From [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader];

		-- Use a while loop to add dates to the table
		Declare @DateInProcess datetime = @StartDate;

		While @DateInProcess <= @EndDate
		 Begin
		  --Add a row into the date dimension table for this date
			 Insert Into [DWAdventureWorksLT2012V2].[dbo].[DimDates] 
				( [CalendarDateKey]
				, [CalendarDateName]
				, [CalendarYearMonthKey]
				, [CalendarYearMonthName]
				, [CalendarYearQuarterKey]
				, [CalendarYearQuarterName]
				, [CalendarYearKey]
				, [CalendarYearName]
				, [CalendarDate]
				, [FiscalDate]
				, [WasUSFederalHoliday]
				)
			 Values ( 
				Convert(nvarchar(50), @DateInProcess, 112) -- [CalendarDateKey]
			  , DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess, 110) --  [CalendarDateName]
			  , Left(Convert(nvarchar(50), @DateInProcess, 112), 6) -- [CalendarYearMonthKey]
			  , DateName( month, @DateInProcess ) -- [CalendarYearMonthName]
			  , Cast(DateName( quarter, @DateInProcess ) +  Cast( Year(@DateInProcess) as nVarchar(50)) as int) --[CalendarYearQuarterKey]
			  , 'Q' + DateName( quarter, @DateInProcess ) + ' - ' + Cast( Year(@DateInProcess) as nVarchar(50)) --[CalendarYearQuarterName]
			  , Year( @DateInProcess ) -- [CalendarYearKey] 
			  , Cast( Year( @DateInProcess) as nVarchar(50) ) -- [CalendarYearName]
			  , Convert([Date], @DateInProcess) 	-- [FiscalDateKey] 			   
			  , Convert([Date], DateAdd(mm,-6,@DateInProcess)) 	-- [FiscalDateKey] 
			  , 0 -- [WasUSFederalHoliday]
			  );  
			 -- Add a day and loop again
			 Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
		 End

		-- Step 2: Add the [WasUSFederalHoliday] bit flag
		UPDATE [DWAdventureWorksLT2012V2].[dbo].[DimDates]
		SET [WasUSFederalHoliday] = 1
		WHERE [CalendarDateKey] in (SELECT [USHolidayID] FROM [DWAdventureWorksLT2012V2].[dbo].[ETLUSHolidays]) 
  
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
-- Create the ETL Flush and Fill Procedures
--********************************************************************--
-- Procedure Template -- 
If (object_id('pETLProcedureTemplate') is not null) Drop PROCEDURE pETLProcedureTemplate;
go
CREATE -- Procedure Template
PROCEDURE pETLProcedureTemplate
AS
	/**************************************************************
	Desc: <Desc Goes Here>
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = '< pETLProcedureTemplate Executed >'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

   Select 3/0 -- Test;
  
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
-- Drop Foreign Key Constraints
--********************************************************************--
If (object_id('pETLDropForeignKeyConstraints') is not null) Drop PROCEDURE pETLDropForeignKeyConstraints;
go
CREATE -- Drop Foreign Key Constraints Procedure
PROCEDURE pETLDropForeignKeyConstraints
AS
	/**************************************************************
	Desc: This procedure will drop all the Foreign Key Constraints
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLDropForeignKeyConstraints'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	ALTER TABLE dbo.DimProducts DROP CONSTRAINT
		fkDimProductsToDimProductCategories; 

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesToDimProducts;

	ALTER TABLE dbo.FactSales DROP CONSTRAINT 
		fkFactSalesToDimCustomers;

	ALTER TABLE dbo.FactCustomersAddresses DROP CONSTRAINT
		fkFactCustomersAddressesToDimCustomers;

	ALTER TABLE dbo.FactCustomersAddresses DROP CONSTRAINT
		fkFactCustomersAddressesToDimAddresses; 

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesOrderDateToDimDates;

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesDueDateToDimDates;

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesShipDateDimDates;

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesShiptoToDimAddresses;

	ALTER TABLE dbo.FactSales DROP CONSTRAINT
		fkFactSalesBilltoToDimAddresses;

	ALTER TABLE dbo.DimProductCategories DROP CONSTRAINT
		fkDimProductCategoriesParentToDimProductCategories;

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
If (object_id('pETLClearTableData') is not null) Drop PROCEDURE pETLClearTableData;
go
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

--********************************************************************--
-- Fill Dimension Tables
--********************************************************************--
If (object_id('pETLFillDimAddresses') is not null) Drop PROCEDURE pETLFillDimAddresses;
go
CREATE -- Fill Dim Addresses Procedure
PROCEDURE pETLFillDimAddresses
AS
	/**************************************************************
	Desc: Fills the DimAddresses dimension table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillDimAddresses'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

	INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[DimAddresses]
	SELECT 
		 [AddressID]
		,[City] = Cast( City as nvarchar(50))
		,[StateProvince]
		,[CountryRegion]
	FROM [AdventureWorksLT2012].[SalesLT].[Address]
  
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

If (object_id('pETLFillDimCustomers') is not null) Drop PROCEDURE pETLFillDimCustomers;
go
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

	INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[DimCustomers]
	SELECT 
		  [CustomerID]
		, [CompanyName] = Cast(CompanyName as nvarchar(200))
		, [ContactFullName] = Cast([FirstName] + ' ' + [LastName] as nvarchar(200))
	FROM [AdventureWorksLT2012].[SalesLT].[Customer];
	  
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

If (object_id('pETLFillDimProductCategories') is not null) Drop PROCEDURE pETLFillDimProductCategories;
go
CREATE -- Fill Dim Product Categories Procedure
PROCEDURE pETLFillDimProductCategories
AS
	/**************************************************************
	Desc: Fills the DimProductCategories dimension table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillDimProductCategories '
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

		  -- Step 1: Get original data and set Null status 
		INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[DimProductCategories]
				   ([ProductCategoryID]
				   ,[ParentProductCategoryKey]
				   ,[ParentProductCategoryID]
				   ,[ProductCategoryName])
		SELECT 
			   T1.[ProductCategoryID]
			  , ParentProductCategoryKey = Null 
			  , [ParentProductCategoryID] = isNull(T1.[ParentProductCategoryID], 0) -- use a temporary  id to indicate which rows are parent categories
			  ,T1.[Name]
		  FROM [AdventureWorksLT2012].[SalesLT].[ProductCategory] as T1;
		-- Select * from [dbo].[DimProductCategories]

		-- Step 2-: Create a temporary lookup table to get category surrogate keys
		Select 
		  T2.[ProductCategoryID]
		,  ProductCategoryKey = T2.[ProductCategoryKey]
		INTO #TempData
		From [DWAdventureWorksLT2012V2].[dbo].[DimProductCategories]  as T1
		Full Join [DWAdventureWorksLT2012V2].[dbo].[DimProductCategories]  as T2
		On T1.ProductCategoryID = T2.ParentProductCategoryID
		Where T2.ParentProductCategoryID = 0;  
		-- Select * from  #TempData

		-- Step 3: Update the table to use the new ProductCategoryKey values for its parent values
		Update DimProductCategories
		Set 
		ParentProductCategoryKey = T2.ProductCategoryKey 
		From DimProductCategories as T1
		Full Join #TempData as T2
		On T1.ParentProductCategoryID = T2.ProductCategoryID 
		-- Select * from [dbo].[DimProductCategories]

		-- Step 4: (optional) Convert the ParentProductCategoryKey and ID null values to self
		Update DimProductCategories
		Set 
		  [ParentProductCategoryKey] = [ProductCategoryKey]
		, [ParentProductCategoryID] = [ProductCategoryID]
		From [dbo].[DimProductCategories]
		Where ParentProductCategoryID = 0;  
		-- Select * from [dbo].[DimProductCategories]
  
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

If (object_id('pETLFillDimProducts') is not null) Drop PROCEDURE pETLFillDimProducts;
go
CREATE -- Fill Dim Products Procedure
PROCEDURE pETLFillDimProducts
AS
	/**************************************************************
	Desc: Fills the DimProducts dimension table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillDimProducts '
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

		INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[DimProducts]
				([ProductID]
				,[ProductName]
				,[ProductNumber]
				,[ProductColor]
				,[ProductStandardCost]
				,[ProductListPrice]
				,[ProductSize]
				,[ProductWeight]
				,[ProductCategoryKey]
				,[ProductModelID]
				,[ProductModelName]
				,[SellStartDate]
				,[SellEndDate]
				,[DiscontinuedDate]
				)
		SELECT 
			   T1.[ProductID] -- [ProductID]
			  ,T1.[Name] -- [ProductName]
			  ,[ProductNumber] =  Cast( T1.ProductNumber as nvarchar(50)) -- [ProductNumber]
			  ,[Color] = IsNull( Cast( T1.[Color]  as nvarchar(50)), 'Not Defined') --[ProductColor] -- A value could be entered, but the source data has not yet defined it
			  ,T1.[StandardCost] --[ProductStandardCost]
			  ,T1.[ListPrice] --[ProductListPrice]
			  ,[Size] = IsNull( T1.[Size], -5) --[ProductSize] -- A value could be entered, but the source data has not yet defined it
			  ,[Weight] = IsNull(T1.[Weight], -5)  --[ProductWeight] -- Leave null for proper weight calculations
		--    ,T1.[ProductCategoryID] 
			  ,T3.[ProductCategoryKey]--[ProductCategoryKey]
			  ,T2.[ProductModelID] --[ProductModelID]
			  ,T2.[Name] --[ProductModelName]
			  ,[SellStartDate] --[SellStartDate]
			  ,[SellEndDate] --[SellEndDate]
			  ,[DiscontinuedDate] --[DiscontinuedDate]
		  FROM [AdventureWorksLT2012].[SalesLT].[Product] as T1
		  JOIN [AdventureWorksLT2012]. [SalesLT].[ProductModel] as T2
			ON T1.ProductModelID = T2.ProductModelID
		 JOIN [DWAdventureWorksLT2012V2].[dbo].[DimProductCategories] as T3
		   ON T1.ProductCategoryID = T3.ProductCategoryID
  
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
-- Fill Fact Tables
--********************************************************************--
If (object_id('pETLFillFactCustomersAddresses') is not null) Drop PROCEDURE pETLFillFactCustomersAddresses;
go
CREATE -- Fill Fact Customers Addresses Procedure
PROCEDURE pETLFillFactCustomersAddresses
AS
	/**************************************************************
	Desc: Fills the FactCustomersAddresses table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillFactCustomersAddresses'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

		INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[FactCustomersAddresses]
				   ([CustomerKey]
				   ,[AddressKey]
				   ,[AddressType])
		SELECT
					 [CustomerKey] 
				   --, T2.[CustomerID]
				   , [AddressKey]
				   --, T3.[AddressID]
				   , [AddressType]
		FROM [AdventureWorksLT2012].[SalesLT].[CustomerAddress] as T1
		JOIN [DWAdventureWorksLT2012V2].[dbo].[DimCustomers] as T2
		  ON T1.[CustomerID] = T2.[CustomerID]
		JOIN [DWAdventureWorksLT2012V2].[dbo].[DimAddresses] as T3
		  ON T1.[AddressID] = T3.[AddressID]
  
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

If (object_id('pETLFillFactSales') is not null) Drop PROCEDURE pETLFillFactSales;
go
CREATE -- Fill Fact Sales Procedure
PROCEDURE pETLFillFactSales
AS
	/**************************************************************
	Desc: Fills the FactSales table
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLFillFactSales'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------

		INSERT INTO [DWAdventureWorksLT2012V2].[dbo].[FactSales]
				   ([SalesOrderID]
				   ,[SalesOrderDetailID]
				   ,[CustomerKey]
				   ,[ProductKey]
				   ,[OrderDateKey]
				   ,[DueDateKey]
				   ,[ShipDateKey]
				   ,[ShipToAddressKey]
				   ,[BillToAddressKey]
				   ,[ShipMethod]
				   ,[OnlineOrderFlag]
				   ,[Status]
				   ,[OrderQty]
				   ,[UnitPrice]
				   ,[UnitPriceDiscount])
		SELECT 
			  T1.[SalesOrderID]  
			, [SalesOrderDetailID] 
			--, T3.[CustomerID]
			, T3.[CustomerKey]
			--, T4.[ProductID]
			, T4.[ProductKey]
			--, [OrderDate] -- 
			, [OrderDateKey] = T5.CalendarDateKey
			--, [DueDate]
			, [DueDateKey]  = T6.CalendarDateKey 
			--, [ShipDate]
			, [ShipDateKey]  = T7.CalendarDateKey
			--, [ShipToAddressID]
			, [ShipToAddressKey] = T8.[AddressKey]
			--, [BillToAddressID]
			, [BillToAddressKey] = T9.[AddressKey]
			, [ShipMethod]
			, [OnlineOrderFlag]
			, [Status]
			, [OrderQty]
			, [UnitPrice]
			, [UnitPriceDiscount]
		  FROM [AdventureWorksLT2012].[SalesLT].[SalesOrderDetail] as T1
		  JOIN [AdventureWorksLT2012].[SalesLT].[SalesOrderHeader] as T2
			ON T1.[SalesOrderID] = T2.[SalesOrderID]
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimCustomers] as T3
			ON T2.[CustomerID] = T3.[CustomerID]
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimProducts] as T4
			ON T4.[ProductID] = T1.[ProductID]
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimDates] as T5
			 ON Cast(T5.CalendarDate as Date) = Cast(T2.[OrderDate] as Date)
		  Left JOIN [DWAdventureWorksLT2012V2].[dbo].[DimDates] as T6
			 ON Cast(T6.CalendarDate as Date) = Cast(T2.[DueDate] as Date)
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimDates] as T7
			 ON Cast(T7.CalendarDate as Date) = Cast(T2.[ShipDate] as Date)
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimAddresses] as T8
			ON T8.[AddressID] = T2.[ShipToAddressID] 
		  JOIN [DWAdventureWorksLT2012V2].[dbo].[DimAddresses] as T9
			ON T9.[AddressID] = T2.[BillToAddressID] 
  
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
-- Replace Foreign Key Constraints
--********************************************************************--
If (object_id('pETLReplaceForeignKeyConstraints') is not null) Drop PROCEDURE pETLReplaceForeignKeyConstraints;
go
CREATE -- Replace Foreign Key Constraints Procedure
PROCEDURE pETLReplaceForeignKeyConstraints
AS
	/**************************************************************
	Desc: <Desc Goes Here>
	ChangeLog: When, How, What
	20160101,RRoot,Created Procedure  
	**************************************************************/
Begin -- Procedure Code
	Declare 
	  @RC int = 0
	, @EventName nvarchar(200) = 'Exec pETLReplaceForeignKeyConstraints'
	, @EventStatus  nvarchar(50) = ''
	, @EventErrorInfo  nvarchar(1000) = ''
	;
 Begin Try 
  Begin Transaction; 
  -- ETL Code  -------------------------------------------------------------------
		ALTER TABLE dbo.DimProducts ADD CONSTRAINT
			fkDimProductsToDimProductCategories FOREIGN KEY (ProductCategoryKey)
			REFERENCES dbo.DimProductCategories (ProductCategoryKey); 

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesToDimProducts FOREIGN KEY (ProductKey) 
			REFERENCES dbo.DimProducts	(ProductKey);

		ALTER TABLE dbo.FactSales ADD CONSTRAINT 
			fkFactSalesToDimCustomers FOREIGN KEY (CustomerKey) 
			REFERENCES dbo.DimCustomers (CustomerKey);

		ALTER TABLE dbo.FactCustomersAddresses ADD CONSTRAINT
			fkFactCustomersAddressesToDimCustomers FOREIGN KEY (CustomerKey) 
			REFERENCES dbo.DimCustomers(CustomerKey);
 
		ALTER TABLE dbo.FactCustomersAddresses ADD CONSTRAINT
			fkFactCustomersAddressesToDimAddresses FOREIGN KEY (AddressKey) 
			REFERENCES dbo.DimAddresses(AddressKey); 

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesOrderDateToDimDates FOREIGN KEY (OrderDateKey) 
			REFERENCES dbo.DimDates(CalendarDateKey);

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesDueDateToDimDates FOREIGN KEY (DueDateKey) 
			REFERENCES dbo.DimDates(CalendarDateKey	);

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesShipDateDimDates FOREIGN KEY (ShipDateKey)
			REFERENCES dbo.DimDates (CalendarDateKey);

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesShiptoToDimAddresses FOREIGN KEY (	ShipToAddressKey)
			REFERENCES dbo.DimAddresses (AddressKey	);

		ALTER TABLE dbo.FactSales ADD CONSTRAINT
			fkFactSalesBilltoToDimAddresses FOREIGN KEY (BillToAddressKey)
			REFERENCES dbo.DimAddresses (AddressKey	);

		ALTER TABLE dbo.DimProductCategories ADD CONSTRAINT
			fkDimProductCategoriesParentToDimProductCategories FOREIGN KEY (ParentProductCategoryKey)
			REFERENCES dbo.DimProductCategories	(ProductCategoryKey);
 
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
-- Test the ETL Objects
--********************************************************************--
-- Test Logging
SET NoCount On;
go

Execute pInsETLEvents
  @ETLEventName = 'Database lookup tables created with script'
, @ETLEventStatus= 'Success'
, @ETLEventErrorInfo = 'NA';
SELECT * FROM ETLEvents ;

-- Test Lookup tables ETL
Execute pETLFillUSHolidaysLookupTable;
Execute pETLFillNullLookupTable;
Execute pETLFillDimDates;

-- Test Pre-Load ETL
Execute pETLDropForeignKeyConstraints;
Execute pETLClearTableData;

-- Test Dimension-Load ETL
Execute pETLFillDimAddresses;
Execute pETLFillDimCustomers;
Execute pETLFillDimProductCategories;
Execute pETLFillDimProducts;

-- Test Fact-Load ETL
Execute pETLFillFactCustomersAddresses;

-- Test Post-Load ETL
Execute pETLReplaceForeignKeyConstraints;
go

Set NoCount Off;
go
--********************************************************************--
-- Verify that the tables are filled
--********************************************************************--
-- Dimension Tables
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[DimAddresses];
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[DimCustomers]; 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[DimDates]; 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[DimProductCategories]; 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[DimProducts]; 
-- Fact Tables 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[FactSales]; 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[FactCustomersAddresses] ; 
-- Lookup Tables
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[ETLNullStatuses]; 
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[ETLUSHolidays];
-- Logging Table
SELECT * FROM [DWAdventureWorksLT2012V2].[dbo].[ETLEvents]; 
go