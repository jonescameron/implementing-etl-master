/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Incremental Loading with Merge --

--( Setup Code )--
'********************************************************************************************'
-- To start, let's create a source and destination table. 
Use TempDB;
Go
-- ResetDemo -- 
	If (object_id('Customers') is not null) Drop Table Customers;
	Create
	Table Customers 
	( CustomerID int Primary Key Identity
	, CustomerName nVarchar(100)
	, CustomerEmail nVarchar(100) Unique);

	If (object_id('DimCustomers') is not null) Drop Table DimCustomers;
	Create
	Table DimCustomers 
	( CustomerID int Primary Key
	, CustomerName nVarchar(100)
	, CustomerEmail nVarchar(100));

	-- Now add some data to the first table. This will be our "SOURCE" table.
	Insert into Customers(CustomerName, CustomerEmail)
		Values ('Bob Smith', 'BSmith@DemoCo.com')
			      , ('Sue Jones', 'SJones@DemoCo.com');
go

-- Since we are going to compare the tables' data a lot, 
--- let's make a Stored Procedure to do so...
If (object_id('pCompareDifferences') is not null) Drop Procedure pCompareDifferences;
go
Create 
Procedure pCompareDifferences
AS
	-- 1) compare the differences with two simple selects
	Select CustomerID, CustomerName, CustomerEmail From Customers;
	Select CustomerID, CustomerName, CustomerEmail From DimCustomers;
Go

--( Incremental Loading with Merge )--
'********************************************************************************************'
-- Let's check out the current data
Exec pCompareDifferences;
go

-- Now, we will use a SQL Merge command to fill the dimension table,
Merge Into DimCustomers as TargetTable
          Using Customers as SourceTable
			ON TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail )
; -- The merge statement demands a semicolon at the end!
go

-- Let's check out the current data
Exec pCompareDifferences;
go

-- Ok, Insert works, but what about updates? --
Update Customers
	Set CustomerName = 'RobertSmith'
	    , CustomerEmail = 'RSmith@DemoCo.com'
	Where CustomerID = 1
go

-- I have modified the Merge command to include Update.
Merge Into DimCustomers as TargetTable
          Using Customers as SourceTable
            On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID 
					            , SourceTable.CustomerName
								, SourceTable.CustomerEmail )
			When Matched -- When the IDs of the row currently being looked match 
			          -- but the Name does not match...
			         AND ( SourceTable.CustomerName <> TargetTable.CustomerName
			         -- or the Email does not match...
			        OR SourceTable.CustomerEmail <> TargetTable.CustomerEmail ) 
			Then 
					UPDATE -- change the data in the Target table (DimCustomers)
					SET TargetTable.CustomerName = SourceTable.CustomerName
						 , TargetTable.CustomerEmail = SourceTable.CustomerEmail
; -- The merge statement demands a semicolon at the end!
go

-- Let's check out the current data
Exec pCompareDifferences;
go

-- Now that we have the Insert and Update working, lets create a code for Deletes --
  Delete
	From Customers
	Where CustomerID = 2;
go

-- I have modified the Merge command to include Update.
Merge Into DimCustomers as TargetTable
        Using Customers as SourceTable
	      On TargetTable.CustomerID = SourceTable.CustomerID
			When Not Matched 
				Then -- The ID in the Source is not found the Target
					INSERT 
					Values ( SourceTable.CustomerID
					            , SourceTable.CustomerName
					            , SourceTable.CustomerEmail )
			When Matched -- When the IDs of the row currently being looked match 
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

-- Let's check out the current data
Exec pCompareDifferences;
go
