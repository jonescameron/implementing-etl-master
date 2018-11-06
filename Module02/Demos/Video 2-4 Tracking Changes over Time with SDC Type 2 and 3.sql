/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Tracking Changes over Time --

--( Setup Code )--
'********************************************************************************************'
-- To start, let's create a source and destination table. 
Use TempDB;
Go

-- Since we are going to be resetting the SOURCE table a lot, 
--- let's make a Stored Procedure to do so...
If (object_id('pResetDemo') is not null) Drop Procedure pResetDemo;
go
Create Procedure pResetDemo
AS
  BEGIN
		If (object_id('Customers') is not null) Drop Table Customers;
		Create
		Table Customers 
		( CustomerID int Primary Key Identity -- SOURCE Original Key 
		, CustomerName nVarchar(100)
		, CustomerEmail nVarchar(100) Unique);

		If (object_id('DimCustomers') is not null) Drop Table DimCustomers;
		Create
		Table DimCustomers 
		( CustomerKey int Primary Key Identity(100,100) -- DESTINATION Surogate Key
		, CustomerID int -- This is our Original Key 
		, CustomerName nVarchar(100)
		, CustomerEmail nVarchar(100));

		-- Now add some data to the first table. This will be our "SOURCE" table.
		Insert into Customers(CustomerName, CustomerEmail)
			Values ('Bob Smith', 'BSmith@DemoCo.com')
					  , ('Sue Jones', 'SJones@DemoCo.com');
  END
go

-- Since we are going to compare the tables' data a lot, 
--- let's make a Stored Procedure to do so...
If (object_id('pCompareDifferences') is not null) Drop Procedure pCompareDifferences;
go
Create 
Procedure pCompareDifferences
AS
  BEGIN
	-- 1) compare the differences with two simple selects
	Select * From Customers;
	Select * From DimCustomers;
  END
go

-- Since we are going to be changing SOURCE data a lot, 
--- let's make a Stored Procedure to do so...
If (object_id('pChangeSourceData') is not null) Drop Procedure pChangeSourceData;
go
Create Procedure pChangeSourceData
AS
  BEGIN
	-- Add a New row
	INSERT into Customers (CustomerName, CustomerEmail) 
		Values ('Tim Thomas', 'TThomas@DemoCo.com' );
	Select * from Customers;
	-- Change an Existing row
	UPDATE Customers 
		Set CustomerName = 'Rob Smith' 
		    , CustomerEmail = 'RSmith@DemoCo.com' 
		Where CustomerId = 1;
	Select * from Customers;
	-- Delete an Existing row
	DELETE from Customers 
		Where CustomerId = 2;
	Select * from Customers;
 END
go

-- Test our Demo Procedures
Exec pResetDemo;
Exec pCompareDifferences;
go

Exec pChangeSourceData;
Exec pCompareDifferences;
go








'*** Slow Changing Dimension Type 1 ***'
-----------------------------------------------------------------------------------------------------------------------
-- (aka: "No One Really Cares")
-- In this method, you just overwrite the existing data and forget it!

-- 1) Start by resetting the source data
Exec pResetDemo;
go

-- 2) Compare the differeces betweee the source and destination
Exec pCompareDifferences;
go

-- 3) Make changes to the source data
Exec pChangeSourceData;
Exec pCompareDifferences;
go

-- 4) Perform our ETL process
Merge Into DimCustomers as TargetTable
        Using Customers as SourceTable
	      On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail )
			When Matched -- When the IDs of the row currently being looked at match 
			          -- but the Name does not match...
			         AND ( SourceTable.CustomerName <> TargetTable.CustomerName
			         -- or the Email does not match...
			        OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
			Then 
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.CustomerName = SourceTable.CustomerName
						 , TargetTable.CustomerEmail = SourceTable.CustomerEmail
			When Not Matched By Source 
				Then -- The CustomerID is in the Target table, but not the source table
					DELETE
	; -- The merge statement demands a semicolon at the end!
go

-- 5) Verify that it worked!
Exec pCompareDifferences;
go





'*** Slow Changing Dimension Type 3 ***'
-----------------------------------------------------------------------------------------------------------------------
-- (aka: "What was it last time?")
-- This method tracks the previous value using separate columns

-- 1) Start by resetting the source data
Exec pResetDemo;
go

-- 2) Change the Destination table to support the type 3 SCD design
ALTER TABLE DimCustomers
	Add PreviousCustomerName varchar(50) Null;
go

-- 3) Compare the differeces between the source and destination
Exec pCompareDifferences;
go

-- 4) Perform our ETL process
Merge Into DimCustomers as TargetTable
        Using Customers as SourceTable
	      On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail
								, Null )  -- ADDED THIS FOR PreviousCustomerName!
			When Matched -- When the IDs of the row currently being looked at match 
			         -- but the Name does not match...
			         AND ( SourceTable.CustomerName <> TargetTable.CustomerName
			         -- or the Email does not match...
			         OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
			Then 
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.CustomerName = SourceTable.CustomerName
						 , TargetTable.CustomerEmail = SourceTable.CustomerEmail
						 , TargetTable.PreviousCustomerName = TargetTable.CustomerName  -- ADDED THIS !
			When Not Matched By Source 
				Then -- The CustomerID is in the Target table, but not the source table
					DELETE
	; -- The merge statement demands a semicolon at the end!
go

-- 5) Verify that it worked!
Exec pCompareDifferences;
go

-- 6) Make changes to the source data
Exec pChangeSourceData;
Exec pCompareDifferences;
go


-- 7) Perform our ETL process
Merge Into DimCustomers as TargetTable
        Using Customers as SourceTable
	      On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail
								, Null )  -- ADDED THIS FOR PreviousCustomerName!
			When Matched -- When the IDs of the row currently being looked at match 
			         -- but the Name does not match...
			         AND ( SourceTable.CustomerName <> TargetTable.CustomerName
			         -- or the Email does not match...
			         OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
			Then 
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.CustomerName = SourceTable.CustomerName
						 , TargetTable.CustomerEmail = SourceTable.CustomerEmail
						 , TargetTable.PreviousCustomerName = TargetTable.CustomerName -- ADDED THIS !
			When Not Matched By Source 
				Then -- The CustomerID is in the Target table, but not the source table
					DELETE
	; -- The merge statement demands a semicolon at the end!
go

-- 8) Verify that it worked!
Exec pCompareDifferences;
go









'*** Slow Changing Dimension Type 2 ***'
-----------------------------------------------------------------------------------------------------------------------
-- (aka: "I want them all!")
-- This popular method tracks an infinite number of versions by just adding 
-- a Version column to the table and forcing people to do only inserts
-- instead of updates or deletes.

-- 1) Start by resetting the source data
Exec pResetDemo;
go

-- 2) Change the Destination table to support the type 3 SCD design
ALTER TABLE DimCustomers
	  Add ChangeStartDate DateTime Null
		  ,  ChangeEndDate DateTime Null
	      ,  IsCurrent char(1) Null Check (IsCurrent in ('y', 'n'));
go

-- 3) Compare the differeces between the source and destination
Exec pCompareDifferences;
go

-- 4) Perform our ETL process
Merge Into DimCustomers as TargetTable
        Using Customers as SourceTable
	      On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail
								, GetDate()  -- ADDED THIS for ChangeStartDate!
								, Null  -- ADDED THIS for ChangeEndDate!
								, 'y' )  -- ADDED THIS for IsCurrent !
			When Matched -- When the IDs of the row currently being looked at match 
			         -- but the Name does not match...
			         AND ( SourceTable.CustomerName <> TargetTable.CustomerName
			         -- or the Email does not match...
			         OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
			Then 
					-- Merge will not allow an insert statement to be used under the MATCHED clause
					-- So, all we can do at this point is to change the IsCurrent status!
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.IsCurrent = 'n'  -- ADDED THIS for IsCurrent !
			When Not Matched By Source 
				Then -- The CustomerID is in the Target table, but not the source table
					-- First, Change the current Matched row
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.ChangeEndDate = GetDate()  -- ADDED THIS for ChangeEndDate!
						 , TargetTable.IsCurrent = 'n'
					-- Now, Add the Changed row		
	; -- The merge statement demands a semicolon at the end!
go

-- 5) Verify that it worked!
Exec pCompareDifferences;
go


'-- Now for the tricky parts! --'
-- 6) Make changes to the source data
Exec pChangeSourceData;
Exec pCompareDifferences;
go


-- 7) Perform our ETL process again, but this time in parts!
	-- 7a: Use Merge to insert and "Delete" (using insert as well!)
	Merge Into DimCustomers as TargetTable
			Using Customers as SourceTable
			  On TargetTable.CustomerID = SourceTable.CustomerID
				When Not Matched 
					Then -- The ID in the Source is not found the Target
						INSERT 
						Values ( SourceTable.CustomerID
									, SourceTable.CustomerName
									, SourceTable.CustomerEmail
									, GetDate()  -- ADDED THIS for ChangeStartDate!
									, Null  -- ADDED THIS for ChangeEndDate!
									, 'y' )  -- ADDED THIS for IsCurrent !
				When Matched -- When the IDs of the row currently being looked at match 
						 -- but the Name does not match...
						 AND ( SourceTable.CustomerName <> TargetTable.CustomerName
						 -- or the Email does not match...
						 OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
				Then 
						-- Merge will not allow an insert statement to be used under the MATCHED clause
						-- So, all we can do at this point is to change the IsCurrent status!
						UPDATE -- change the data in the Target table (DimCustomers)
						SET TargetTable.IsCurrent = 'n'  -- ADDED THIS for IsCurrent !
				When Not Matched By Source 
					Then -- The CustomerID is in the Target table, but not the source table
						-- First, Change the current Matched row
						UPDATE -- change the data in the Target table (DimCustomers)
						SET TargetTable.ChangeEndDate = GetDate()  -- ADDED THIS for ChangeEndDate!
							 , TargetTable.IsCurrent = 'n'
	; -- The merge is done, but we still new to add the Updated rows

	-- TEST: Exec pCompareDifferences;  and Note that Bob, has not be updated to Rob!

	-- 7c: Add any Rows that were updated to the table Variable after we 
	-- synchronize any Inserts or Deletes.
	Insert into DimCustomers
		( CustomerId
		, CustomerName
		, CustomerEmail
		, ChangeStartDate
		, ChangeEndDate
		, IsCurrent)
		Select CustomerId, CustomerName, CustomerEmail, GetDate(), Null, 'y' from Customers 
		Except 
		Select CustomerId, CustomerName, CustomerEmail, GetDate(), Null, 'y' from DimCustomers

-- 8) Verify that it worked!
Exec pCompareDifferences;
go

' For better performance, but additional complexity, use the Merges OUTPUT clause...'

