/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- [ VIDEO 5.3 Error Handling in SQL Server ]--

-- Variables are scoped to a batch
Declare @Number1 float = 5, @Number2 float = 2;
Select [Sum] =  @Number1 + @Number2;
Select [Difference] =  @Number1 - @Number2;
Select [Product] =  @Number1 * @Number2;
Select [Quotient] =  @Number1 / @Number2;
go-- goseparates batchs of SQL Statements in SSMS
Select [Quotient] =  @Number1 / @Number2;

-- Begin and End Logicaly group statements, but do not have scope
Begin
	Declare @Number1 float = 5, @Number2 float = 2;
	Select [Sum] =  @Number1 + @Number2;
	Select [Difference] =  @Number1 - @Number2;
	Select [Product] =  @Number1 * @Number2;
	Select [Quotient] =  @Number1 / @Number2;
End
Select [Quotient] =  @Number1 / @Number2;
go-- goseparates batchs of SQL Statements in SSMS
Select [Quotient] =  @Number1 / @Number2;
go

 -- Begin and End are often used with If Statements
Declare @Number1 float = 5, @Number2 float = 0;
IF (@Number2 <> 0)
	Begin 
		Select [Sum] =  @Number1 + @Number2;
		Select [Difference] =  @Number1 - @Number2;
		Select [Product] =  @Number1 * @Number2;
		Select [Quotient] =  @Number1 / @Number2;
	End
Select [Sum] =  @Number1 + @Number2; -- This runs reguardless of the indent!
go

 -- IF / Else has often been used to handle errors
Declare @Number1 float = 5, @Number2 float = 0;
IF (@Number2 <> 0)
	Begin -- None of these process
		Select [Sum] =  @Number1 + @Number2;
		Select [Difference] =  @Number1 - @Number2;
		Select [Product] =  @Number1 * @Number2;
		Select [Quotient] =  @Number1 / @Number2;
	End
ELSE -- the Else clause can be used for handling invalid numbers
	Begin
		Print 'Do Not use '  + Cast(@Number2 as nvarchar(50)) + ' as the second number!';
	End
go

-- Try / Catch is the newer recommend way of handling errors
Declare @Number1 float = 5, @Number2 float = 0;
Begin Try -- All process UNTIL an error
	Select [Sum] =  @Number1 + @Number2;
	Select [Difference] =  @Number1 - @Number2;
	Select [Product] =  @Number1 * @Number2;
	Select [Quotient] =  @Number1 / @Number2;
End Try
Begin Catch
	Print 'Do Not use '  + Cast(@Number2 as nvarchar(50)) + ' as the second number!';
End Catch
go

-- Performing Transaction statements like Insert | Update | Delete 
USE TEMPDB;
If (object_id('Mod5Demo') is not null) Drop Table Mod5Demo;
go
Create Table TempDB.dbo.Mod5Demo (ID int Primary Key, Name nvarchar(100));
go

Declare @ID int = 5, @Name nvarchar(100) = 'Bob Smith';
Begin Try
	Begin Transaction -- Add Transaction Code
		Insert into TempDB.dbo.Mod5Demo (ID, Name) Values (@ID, @Name);
	Commit Transaction -- All went well
End Try
Begin Catch
	Print 'ERROR: The ID '  + Cast(@ID as nvarchar(50)) + ' and Name ' + @Name + ' were not inserted!' ; -- Custom Message
	Print ERROR_Message(); -- Built-in error function
	Rollback Transaction -- Something failed
End Catch
go

SELECT * From TempDB.dbo.Mod5Demo;
go


-- [ VIDEO 5.3 Common SSIS Errors when using SQL Code ] --

Use TempDB;
go

Select Count(*) 
From [DWAdventureWorksLT2012V2].[dbo].[DimProducts]; 
go

Declare @MinPrice money = 1000;
Select Count(*) 
 From  [DWAdventureWorksLT2012V2].[dbo].[DimProducts] 
 Where [ProductListPrice] > @MinPrice;
go

Declare @MinPrice money = 1000, @ProductCount int;
Select @ProductCount = Count(*) 
 From [DWAdventureWorksLT2012V2].[dbo].[DimProducts] 
 Where [ProductListPrice] > @MinPrice;
Select @ProductCount as [Number of Products above min price];
go

If (object_id('pSelProductCountByMinPrice') is not null) Drop Procedure pSelProductCountByMinPrice;
go
Create Procedure pSelProductCountByMinPrice
(@MinPrice money, @ProductCount int output)
AS
Begin
 Declare @RC int; -- Used to indicate status of code execution
 Begin Try
  Select @ProductCount = Count(*) 
   From [DWAdventureWorksLT2012V2].[dbo].[DimProducts] 
    Where [ProductListPrice] > @MinPrice;
  Set @RC = 100;
 End Try
 Begin Catch
  Set @RC = -100;
 End Catch
 Return @RC;
End
go

-- Test the stored procedure
Declare @ReturnCode int, @CountOutput int;
Exec @ReturnCode = pSelProductCountByMinPrice
 @MinPrice = 1000
,@ProductCount = @CountOutput output;
-- Show the results
Select 
 @CountOutput as [Number of Products about min price]
,@ReturnCode as [Status of Code];
go





























-- [ VIDEO 5.5 Logging in SQL Server ] --


-- Errors can be logged into the Windows Event Log
USE TEMPDB;
If (object_id('Mod5Demo') is not null) Drop Table Mod5Demo;
go
Create Table TempDB.dbo.Mod5Demo (ID int Primary Key, Name nvarchar(100));
go


Declare @ID int = 5, @Name nvarchar(100) = 'Bob Smith';
Begin Try -- All process until an error
	Begin Transaction 
		Insert into TempDB.dbo.Mod5Demo (ID, Name) Values (@ID, @Name);
	Commit Transaction
End Try
Begin Catch  
	Declare @ErrorMessage nvarchar(100) = 'ERROR: The ID '  + Cast(@ID as nvarchar(50)) 
																		   + ' and Name ' + @Name + ' were not inserted!'
	RaisError(@ErrorMessage, 15, 1) With Log ; -- Writes error in the Windows Event Log
	Print ERROR_Message();
	Rollback Transaction
End Catch
go

SELECT * From TempDB.dbo.Mod5Demo;
go




-- Logged into a custom table
USE TEMPDB;
If (object_id('ETLEvents') is not null) Drop Table ETLEvents;
go
CREATE -- Logging Table
TABLE ETLEvents
( ETLEventID int 
, ETLEventMessage nvarchar(1000) Not Null 
);
go

Declare @ID int = 5, @Name nvarchar(100) = 'Bob Smith';
Begin Try 
	Begin Transaction 
		Insert into TempDB.dbo.Mod5Demo (ID, Name) Values (@ID, @Name);
	Commit Transaction
End Try
Begin Catch  
	Declare @ErrorMessage nvarchar(100) = 'ERROR: The ID '  + Cast(@ID as nvarchar(50)) 
																		   + ' and Name ' + @Name + ' were not inserted!'
	RaisError(@ErrorMessage, 15, 1) With Log ; 
	Print ERROR_Message();
	Rollback Transaction

	Insert into ETLEvents Values ( -- Writes error to a custom logging table
	   Cast (ERROR_NUMBER() as int)
     , Cast(ERROR_MESSAGE()  as varchar(50))  
	 );

End Catch
go

SELECT * From TempDB.dbo.ETLEvents;
go
