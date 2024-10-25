USE HR;
GO

;WITH CTE AS 
(

SELECT x.ManagerID, x.EmployeeID, x.EmpName, x.Title, CAST(x.Title AS NVARCHAR(MAX)) AS TitleTree, CAST(x.EmployeeID AS NVARCHAR(MAX)) AS TitleIdTree,0 AS Level -- IMPORTANT: Only MAX is accepted
FROM dbo.Employees x
WHERE x.ManagerID IS NULL

UNION ALL

SELECT x.ManagerID, x.EmployeeID, x.EmpName, x.Title, CAST(LTRIM(RTRIM(x.Title))+' < '+LTRIM(RTRIM(c.TitleTree)) AS NVARCHAR(MAX)), CAST(LTRIM(RTRIM(c.TitleIdTree)+' > '+LTRIM(RTRIM(x.EmployeeID))) AS NVARCHAR(MAX)),c.Level+1
FROM dbo.Employees x
JOIN CTE c ON c.EmployeeID=x.ManagerID

)
SELECT * FROM CTE b
ORDER BY b.Level