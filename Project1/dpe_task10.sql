/****** Object:  Schema [dpe_task_schema]    Script Date: 31-01-2025 06:12:18 PM ******/
CREATE SCHEMA [dpe_task_schema]
GO
/****** Object:  View [dpe_task_schema].[Vw_CategoryWisePriceStats]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dpe_task_schema].[Vw_CategoryWisePriceStats] AS (  
    SELECT   
        b.[Name] AS Category,   
        MIN(a.ListPrice) AS MinimumPrice,   
        MAX(a.ListPrice) AS MaximumPrice,   
        AVG(a.ListPrice) AS AveragePrice  
    FROM   
        [SalesLT].[Product] a
    LEFT JOIN   
        SalesLT.ProductCategory b ON a.ProductCategoryID = b.ProductCategoryID  
    WHERE   
        b.[Name] IN ('Road Bikes', 'Mountain Bikes', 'Touring Bikes')  
    GROUP BY   
        b.[Name]  
)
GO
/****** Object:  View [dpe_task_schema].[Vw_CategoryWisePriceStatsDimension]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dpe_task_schema].[Vw_CategoryWisePriceStatsDimension] AS(  
SELECT   
    'Minimum Price' AS Dimension,  
    MAX(CASE WHEN Category = 'Mountain Bikes' THEN MinimumPrice END) AS "Mountain Bikes",  
    MAX(CASE WHEN Category = 'Road Bikes' THEN MinimumPrice END) AS "Road Bikes",  
    MAX(CASE WHEN Category = 'Touring Bikes' THEN MinimumPrice END) AS "Touring Bikes"  
FROM dpe_task_schema.Vw_CategoryWisePriceStats  
UNION ALL  
SELECT   
    'Maximum Price',  
    MAX(CASE WHEN Category = 'Mountain Bikes' THEN MaximumPrice END),  
    MAX(CASE WHEN Category = 'Road Bikes' THEN MaximumPrice END),  
    MAX(CASE WHEN Category = 'Touring Bikes' THEN MaximumPrice END)  
FROM dpe_task_schema.Vw_CategoryWisePriceStats  
UNION ALL  
SELECT   
    'Average Price',  
    MAX(CASE WHEN Category = 'Mountain Bikes' THEN AveragePrice END),  
    MAX(CASE WHEN Category = 'Road Bikes' THEN AveragePrice END),  
    MAX(CASE WHEN Category = 'Touring Bikes' THEN AveragePrice END)  
FROM dpe_task_schema.Vw_CategoryWisePriceStats
)
GO
/****** Object:  UserDefinedFunction [dpe_task_schema].[function_getinfoproduct_fromproductcategory]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dpe_task_schema].[function_getinfoproduct_fromproductcategory](@productcategoryname nvarchar(max))
RETURNS TABLE
AS
RETURN
(
SELECT fin_tab.ProductName,fin_tab.ProductDescription,fin_tab.ProductPrice,
fin_tab.MinimumCategoryPrice,fin_tab.MaximumCategoryPrice,fin_tab.AverageCategoryPrice
FROM
(SELECT d.[Name] AS ProductCategoryName, b.[Name] AS ProductName, c.[Description] AS ProductDescription, b.ListPrice AS ProductPrice,
MAX(b.ListPrice) OVER (PARTITION BY b.ProductCategoryID) AS MaximumCategoryPrice,
MIN(b.ListPrice) OVER (PARTITION BY b.ProductCategoryID) AS MinimumCategoryPrice,
AVG(b.ListPrice) OVER (PARTITION BY b.ProductCategoryID) AS AverageCategoryPrice,
ROW_NUMBER() OVER (PARTITION BY b.ProductCategoryID ORDER BY e.TotalOrderQty DESC) AS Popularity
FROM [SalesLT].[ProductModelProductDescription] a 
LEFT JOIN [SalesLT].[Product] b ON a.ProductModelID=b.ProductModelID
LEFT JOIN [SalesLT].[ProductDescription] c ON a.ProductDescriptionID = c.ProductDescriptionID
LEFT JOIN  [SalesLT].[ProductCategory] d ON b.ProductCategoryID=d.ProductCategoryID
LEFT JOIN 
(SELECT ProductID, Sum(OrderQty) AS TotalOrderQty
FROM [SalesLT].[SalesOrderDetail]
GROUP BY ProductID) e
ON b.ProductID = e.ProductID) fin_tab
WHERE fin_tab.Popularity=1 AND
fin_tab.ProductCategoryName = @productcategoryname
)
GO
/****** Object:  View [dpe_task_schema].[Vw_MtBikes_DescPrice]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dpe_task_schema].[Vw_MtBikes_DescPrice] AS  
SELECT a.[ProductID], a.[Name], a.[ProductNumber]  
FROM (  
    SELECT   
        first_table.[ProductID],   
        first_table.[Name],   
        first_table.[ProductNumber],  
        ROW_NUMBER() OVER (ORDER BY first_table.ListPrice DESC) AS PriceRank  
    FROM [SalesLT].[Product] first_table  
    INNER JOIN [SalesLT].[ProductCategory] second_table  
        ON first_table.ProductCategoryID = second_table.ProductCategoryID  
    WHERE second_table.[Name] = 'Mountain Bikes'  
) a; 
GO
/****** Object:  View [dpe_task_schema].[Vw_MtBikes_NeverSold_AscPrice]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dpe_task_schema].[Vw_MtBikes_NeverSold_AscPrice] AS
SELECT a.ProductID,a.[Name],a.ProductNumber FROM
(SELECT first_table.[ProductID], first_table.[Name],first_table.[ProductNumber],
ROW_NUMBER() OVER (ORDER BY first_table.ListPrice ASC) AS PriceRank
FROM [SalesLT].[Product] first_table
LEFT JOIN [SalesLT].[ProductCategory] second_table
ON first_table.ProductCategoryID = second_table.ProductCategoryID
WHERE second_table.[Name] = 'Mountain Bikes') a 
LEFT JOIN
[SalesLT].[SalesOrderDetail] b
ON a.ProductID = b.ProductID
WHERE b.ProductID IS NULL
GO
/****** Object:  View [dpe_task_schema].[Vw_MultiColor_DefinedSize_Under700_ProductIDs]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dpe_task_schema].[Vw_MultiColor_DefinedSize_Under700_ProductIDs] AS  
SELECT ProductID  
FROM [SalesLT].[Product]  
WHERE ListPrice < 700   
  AND Color = 'Multi'   
  AND Size IS NOT NULL;
GO
/****** Object:  StoredProcedure [dpe_task_schema].[sp_getcolorfromcategory]    Script Date: 31-01-2025 06:12:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dpe_task_schema].[sp_getcolorfromcategory]
    @ProductCategoryName NVARCHAR(255)  
AS  
BEGIN  
    DECLARE @Colors NVARCHAR(MAX);  
  
    -- Concatenate all available colors for the specified product category  
    SELECT @Colors = STRING_AGG(joined_table.Color, ',')  
    FROM 
	(SELECT DISTINCT b.[Color]
	FROM [SalesLT].[ProductCategory] a
	LEFT JOIN [SalesLT].[Product] b
	ON a.ProductCategoryID = b.ProductCategoryID
	WHERE a.[Name] = @ProductCategoryName) joined_table;  
  
    -- Check if any colors were found, otherwise return a default message  
    IF @Colors IS NULL  
    BEGIN  
        SELECT 'No color selections for this category' AS Colors;  
    END  
    ELSE  
    BEGIN  
        SELECT @Colors AS Colors;  
    END  
END;  

GO
