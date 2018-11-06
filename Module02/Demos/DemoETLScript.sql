/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/

--********************************************************************--
-- ETL Pre-Load Tasks
--********************************************************************--
-- 1) Drop Foreign Keys -- NA
-- 2) Clear Flush and Fill Tables
Truncate Table FactSales;
Truncate Table DimProducts;
Truncate Table DimCustomers;

--********************************************************************--
-- ETL Dimension Load Tasks
--********************************************************************--
-- 3) Load Flush and Fill Dimension Tables
Declare @ReturnCode int;
Execute @ReturnCode = pETLDimProducts;
Select [pETLDimProducts Status] = @ReturnCode;

Execute @ReturnCode = pETLDimCustomers;
Select [pETLDimCustomers Status] =  @ReturnCode;
go

-- 4) Load Incremental Loading Dimension Tables -- NA

--********************************************************************--
-- ETL Fact Load Tasks
--********************************************************************--
-- 5) Load Flush and Fill Dimension Tables

Declare @ReturnCode int;
Execute @ReturnCode = pETLFactSales;
Select  [pETLFactSales Status] =  @ReturnCode;
go

-- 6) Load Incremental Loading Dimension Tables -- NA

--********************************************************************--
-- ETL Post-Load Tasks
--********************************************************************--
-- 7) Replace Foreign Keys -- NA


Select * from DimCustomers
Select * from DimProducts
Select * from DimDates
Select * from FactSales
go