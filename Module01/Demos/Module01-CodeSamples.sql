/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

-- Code used in Module 01 --
USE TEMPDB;
go

-- Listing 1-01. Using SQL Column Aliases
SELECT 
  [TitleId] = [title_id]  -- Column aliases on the left run the same as this syntax [title_id] as [TitleId].
, [TitleName] = [title] 
, [TitleType] = [type] 
FROM [pubs].[dbo].[titles]
go

-- Listing 1-2. Transforming Data Using Select – Case
SELECT 
  [TitleId] = [title_id] 
, [TitleName] = [title]
, [TitleType] = CASE [type] 
   When 'business' Then 'Business'
   When 'mod_cook' Then 'Modern Cooking'						     
   When 'popular_comp' Then 'Popular Computing'					 
   When 'psychology' Then 'Psychology'						 
   When 'trad_cook' Then 'Traditional Cooking'	
   When 'UNDECIDED' Then 'Undecided'							     
  End
FROM [pubs].[dbo].[titles];
go

 
-- Listing 1-3. Code Defining the Titles table
/* In the real table there are a number of other columns, but I am keeping things simiple by ignoring them here.
CREATE TABLE [dbo].[titles]
( [title_id] [char](6) NOT NULL
, [title] [varchar](80) NOT NULL
, [type] [char](12) NOT NULL
);
*/



-- Listing 1-4. Converting Data Using Cast
SELECT 
  [TitleId] = [title_id] 
, [TitleName] = CAST([title] as nVarchar(100)) 
, [TitleType] = CASE CAST([type] as nVarchar(100)) 
   When 'business' Then 'Business'
   When 'mod_cook' Then 'Modern Cooking'						     
   When 'popular_comp' Then 'Popular Computing'					 
   When 'psychology' Then 'Psychology'						 
   When 'trad_cook' Then 'Traditional Cooking'	
   When 'UNDECIDED' Then 'Undecided'							     
  End
FROM [pubs].[dbo].[titles];
go 
 
-- Listing 1-5. Inserting Transformed Data
Use TempDB;
Go
-- Create a reporting table 
CREATE TABLE [dbo].[DimTitles]
( [TitleId] [char](6) NOT NULL
, [TitleName] [nVarchar](100) NOT NULL
, [TitleType] [nVarchar](100) NOT NULL
);
go
-- Add transformed data
INSERT INTO [TempDB].[dbo].[DimTitles]
 SELECT 
   [TitleId] = [title_id] 
 , [TitleName] = CAST([title] as nVarchar(100)) 
 , [TitleType] = CASE CAST([type] as nVarchar(100)) 
    When 'business' Then 'Business'
    When 'mod_cook' Then 'Modern Cooking'						     
    When 'popular_comp' Then 'Popular Computing'					 
    When 'psychology' Then 'Psychology'						 
    When 'trad_cook' Then 'Traditional Cooking'	
    When 'UNDECIDED' Then 'Undecided'							     
   End
 FROM [pubs].[dbo].[titles];
go


-- Listing 1-6. Creating an ETL View
Use TempDB;
go
CREATE VIEW vETLSelectSourceDataForDimTitles
AS
 SELECT 
   [TitleId] = [title_id] 
 , [TitleName] = CAST([title] as nVarchar(100)) 
 , [TitleType] = CASE CAST([type] as nVarchar(100)) 
    When 'business' Then 'Business'
    When 'mod_cook' Then 'Modern Cooking'						     
    When 'popular_comp' Then 'Popular Computing'					 
    When 'psychology' Then 'Psychology'						 
    When 'trad_cook' Then 'Traditional Cooking'	
    When 'UNDECIDED' Then 'Undecided'							     
   End
FROM [pubs].[dbo].[titles];
go

-- Listing 1-7. Using the View
SELECT 
  [TitleId]
, [TitleName]
, [TitleType]
FROM vETLSelectSourceDataForDimTitles;
go

-- Listing 1-8. View for the Author's Table
-- Select au_fname + ' ' + au_lname as AuthorName, phone as AuthorPhoneNumber into Authors from pubs.dbo.authors;
CREATE VIEW vETLAuthors
AS
 SELECT 
   [AuthorName]
 , [AuthorPhoneNumber] 
 FROM Authors;
 go

-- Listing 1-9. Modified View for the Author's Table
 --Drop Table Authors;
 --Select au_fname as AuthorFirstName, au_lname as AuthorLastName, phone as AuthorPhoneNumber into Authors from pubs.dbo.authors;
ALTER VIEW vETLAuthors
AS
 SELECT 
   [AuthorName] = AuthorFirstName + ' ' + AuthorLastName
 , [AuthorPhoneNumber] 
 FROM Authors;
 go

-- Listing 1-10. Creating an ETL Procedure
CREATE PROCEDURE pETLInsDataToDimTitles
AS
 DELETE FROM [TempDB].[dbo].[DimTitles];
 INSERT INTO [TempDB].[dbo].[DimTitles]
 SELECT 
   [TitleId]
 , [TitleName]
 , [TitleType]
 FROM vETLSelectSourceDataForDimTitles;
go
EXECUTE pETLInsDataToDimTitles;
go
SELECT * FROM [TempDB].[dbo].[DimTitles]
go
