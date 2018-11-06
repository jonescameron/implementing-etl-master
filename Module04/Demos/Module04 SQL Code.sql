/*************************************************************
*                                                            *
*   Copyright (C) Microsoft Corporation. All rights reserved.*
*                                                            *
*************************************************************/


-- Module04 ETL Demos Code Examples
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE DWAdventureWorksLT2012v1;

--[ VIDEO 4.6 Derived Columns ]--
If (object_id('vETLDimCustomers') is not null) Drop Table vETLDimCustomers;
go
CREATE VIEW vETLDimCustomers
AS
	SELECT 
	  [CustomerID] = [CustomerID]
	, [ContactFullName] = Convert( nvarchar(200), [FirstName] + ' ' + [LastName])
	, [CompanyName] = Cast( [CompanyName] AS nvarchar(200) )
	, [SalesPersonAlias] = Cast( Substring( [SalesPerson], PatIndex( '%\%',[SalesPerson] ) + 1, 128 ) AS nvarchar(200) )
	FROM [AdventureWorksLT2012].[SalesLT].[Customer]
	;
go


SELECT 
  [CustomerID] 
, [FirstName] 
, [LastName]
, [CompanyName] = Cast( [CompanyName] AS nvarchar(200) )
, [SalesPerson] = Cast( [SalesPerson] AS nvarchar(200) )
FROM [AdventureWorksLT2012].[SalesLT].[Customer]
ORDER BY [CustomerID] 
;


--[ VIDEO 4.6 Aggregate ]--
If (object_id('vETLFactSales') is not null) Drop Table vETLFactSales;
go
CREATE VIEW vETLFactSales
AS
	SELECT 
	  SalesOrderID = T2.SalesOrderID
	, SalesOrderDetailID = T1.SalesOrderDetailID
	, OrderDateKey = T6.CalendarDateKey
	, ShipDateKey = T5.CalendarDateKey
	, CustomerKey = T4.CustomerKey
	, ProductKey = T3.ProductKey
	, OrderQty = T1.OrderQty
	, UnitPrice = T1.UnitPrice
	, UnitPriceDiscount = T1.UnitPriceDiscount
	FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
	JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
	  ON T1.SalesOrderID = T2.SalesOrderID
	JOIN DWAdventureWorksLT2012v1.dbo.DimProducts as T3
	 ON T1.ProductID = T3.ProductID
	JOIN DWAdventureWorksLT2012v1.dbo.DimCustomers as T4
	 ON T2.CustomerID = T4.CustomerID
	JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T5
	 ON Cast(T2.ShipDate as date) = Cast(T5.CalendarDate as date)
	JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T6
	 ON Cast(T2.OrderDate as date) = Cast(T6.CalendarDate as date)
	;
go


-- Without SQL Aggregates and Group By
SELECT 
  SalesOrderID = T2.SalesOrderID
, SalesOrderDetailID = T1.SalesOrderDetailID
, OrderDateKey = T6.CalendarDateKey
, ShipDateKey = T5.CalendarDateKey
, CustomerKey = T4.CustomerKey
, ProductKey = T3.ProductKey
, OrderQty = T1.OrderQty
, UnitPrice = T1.UnitPrice
, UnitPriceDiscount = T1.UnitPriceDiscount
FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
	ON T1.SalesOrderID = T2.SalesOrderID
JOIN DWAdventureWorksLT2012v1.dbo.DimProducts as T3
	ON T1.ProductID = T3.ProductID
JOIN DWAdventureWorksLT2012v1.dbo.DimCustomers as T4
	ON T2.CustomerID = T4.CustomerID
JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T5
	ON Cast(T2.ShipDate as date) = Cast(T5.CalendarDate as date)
JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T6
	ON Cast(T2.OrderDate as date) = Cast(T6.CalendarDate as date)
ORDER BY 
1,2,3,4,5,6

-- With SQL Aggregates and Group By
SELECT 
  SalesOrderID = T2.SalesOrderID
, SalesOrderDetailID = T1.SalesOrderDetailID
, OrderDateKey = T6.CalendarDateKey
, ShipDateKey = T5.CalendarDateKey
, CustomerKey = T4.CustomerKey
, ProductKey = T3.ProductKey
, OrderQty = SUM(T1.OrderQty) -- Sum is required if the granularity in the Source ...
, UnitPrice = SUM(T1.UnitPrice) -- ... is different then in the Destination!
, UnitPriceDiscount = SUM(T1.UnitPriceDiscount)
FROM  [AdventureWorksLT2012].SalesLT.SalesOrderDetail as T1
JOIN [AdventureWorksLT2012].SalesLT.SalesOrderHeader as T2
ON T1.SalesOrderID = T2.SalesOrderID
JOIN DWAdventureWorksLT2012v1.dbo.DimProducts as T3
ON T1.ProductID = T3.ProductID
JOIN DWAdventureWorksLT2012v1.dbo.DimCustomers as T4
ON T2.CustomerID = T4.CustomerID
JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T5
ON Cast(T2.ShipDate as date) = Cast(T5.CalendarDate as date)
JOIN DWAdventureWorksLT2012v1.dbo. DimDates as T6
ON Cast(T2.OrderDate as date) = Cast(T6.CalendarDate as date)
GROUP BY -- Requred if using an Aggregate Function
  T2.SalesOrderID
, T1.SalesOrderDetailID
, T6.CalendarDateKey
, T5.CalendarDateKey
, T4.CustomerKey
, T3.ProductKey
ORDER BY 
1,2,3,4,5,6
;