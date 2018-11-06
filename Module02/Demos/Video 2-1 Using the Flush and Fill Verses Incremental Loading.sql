/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Using the Flush and Fill Verses Incremental Loading  --


Use TempDB;
Go

--( Setup Code )--
'********************************************************************************************'
-- To start, let's create a source and destination table. 

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
		Values ('Bob Smith' , 'BSmith@DemoCo.com')
			      , ('Sue Jones' , 'SJones@DemoCo.com');
go

-- Since we are going to compare the tables' data a lot, 
--- let's make a Stored Procedure like this one...
If (object_id('pCompareDifferences') is not null) Drop Procedure pCompareDifferences;
go
Create 
Procedure pCompareDifferences
AS
	-- 1) compare the differences with two simple selects
	Select CustomerID, CustomerName, CustomerEmail From Customers;
	Select CustomerID, CustomerName, CustomerEmail From DimCustomers;
Go

-- Also, we can transfer data using a Flush and Fill Procedure like this one...
If (object_id('pFlushAndFillDimCustomers') is not null) Drop Procedure pFlushAndFillDimCustomers;
go
Create 
Procedure pFlushAndFillDimCustomers
AS 
	Delete From DimCustomers;
	Insert Into DimCustomers(CustomerID, CustomerName, CustomerEmail)
		Select CustomerID, CustomerName, CustomerEmail 
		From Customers
go




--( USING Flush and Fill )--
'********************************************************************************************'
-- Now we will synchronize the tables using our Flush and Fill Procedure
Exec pFlushAndFillDimCustomers
Exec pCompareDifferences;


-- Let's add a new row of data and compare the differences between tables
Insert into Customers(CustomerName, CustomerEmail)
	Values ('Tim Thomas' , 'TThomas@DemoCo.com');
Exec pCompareDifferences;
Go

-- Now we will synchronize the tables using our Flush and Fill Procedure
Exec pFlushAndFillDimCustomers
Exec pCompareDifferences;
Go

-- If later someone updates a Customer's data
Update Customers
	Set CustomerName = 'RobertSmith'
	    , CustomerEmail = 'RSmith@DemoCo.com'
	Where CustomerID = 1;
Exec pCompareDifferences;
Go

-- We just run the Flush and Fill code again.
Exec pFlushAndFillDimCustomers
Exec pCompareDifferences;
Go

-- And, we still use the same code for Deletes
Delete
	From Customers
	Where CustomerID = 2;
Exec pCompareDifferences;
Go

-- We just run the Flush and Fill code again.
Exec pFlushAndFillDimCustomers
Exec pCompareDifferences;
Go








--( Incremental Loading )--
'********************************************************************************************'

-- Let's add a new row of data
Insert into Customers(CustomerName, CustomerEmail)
	Values ('Sue Jones' , 'SJones@DemoCo.com');
Exec pCompareDifferences;
Go

-- We can transfer data to the dimension table by using an INSERT statement combined with a EXCEPT predicate. 
With ChangedCustomers 
As
(	-- Find all the IDs that a new.
	Select CustomerID From Customers -- What is in this table...
	Except
	Select CustomerID From DimCustomers -- that is NOT in this one?
)
Insert Into DimCustomers(CustomerID, CustomerName, CustomerEmail)
	Select CustomerID, CustomerName, CustomerEmail From Customers
	Where CustomerID in (Select CustomerID from ChangedCustomers);

-- And, compare the differences
Exec pCompareDifferences;
go

-- Ok, so that works with an Insert but what about updates? --
Update Customers
	Set CustomerName = 'RobSmith'
	  , CustomerEmail = 'RSmith@DemoCo.com'
	Where CustomerID = 1;
go

-- Now, let's compare the differences
Exec pCompareDifferences;
go

-- Then, let's force an update to the tables where there are differences in the rows, using Correlated Subqueries.
With ChangedCustomers 
As
(	-- Find rows that have different data
	Select CustomerID, CustomerName, CustomerEmail From Customers
	Except
	Select CustomerID, CustomerName, CustomerEmail From DimCustomers
)
Update DimCustomers
	Set CustomerName = (Select CustomerName 
										 From ChangedCustomers 
										 Where ChangedCustomers.CustomerID = DimCustomers.CustomerID) -- This query runs for each row being updated!
	    , CustomerEmail = (Select CustomerEmail 
										From ChangedCustomers 
										Where ChangedCustomers.CustomerID = DimCustomers.CustomerID) -- So does this one!
	Where CustomerId In (Select CustomerId 
										From ChangedCustomers ) ;

-- Now, let's compare the differences.
Exec pCompareDifferences;
go


-- Now that we have the Insert and Update working, lets create a code for Deletes --
  Delete
	From Customers
	Where CustomerID = 3;

-- Now, let's compare the differences.
Exec pCompareDifferences;
go

With ChangedCustomers 
As
( -- Note that I had to CHANGE THE ORDER of the tables to make the delete work!
	Select CustomerID, CustomerName, CustomerEmail From DimCustomers
	Except
	Select CustomerID, CustomerName, CustomerEmail From Customers
)
Delete 
	From DimCustomers
	Where CustomerID In (Select CustomerID from ChangedCustomers)

-- Now, let's compare the differences.
Exec pCompareDifferences;
go




