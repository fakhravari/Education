USE HR;
GO

WITH DirectReports ( ManagerID,	EmployeeID,	EmpName,	Title,	TitleTree,	TitleIdTree,	Level)
AS
(
SELECT x.ManagerID, x.EmployeeID, x.EmpName, x.Title, CAST(x.Title AS NVARCHAR(MAX)) AS TitleTree, CAST(x.EmployeeID AS NVARCHAR(MAX)) AS TitleIdTree,0 AS Level -- IMPORTANT: Only MAX is accepted
FROM dbo.Employees x
WHERE x.EmployeeID = 10
    
UNION ALL
    
SELECT E.ManagerID, E.EmployeeID , E.EmpName,E.Title,CAST(LTRIM(RTRIM(E.Title))+' < '+LTRIM(RTRIM(DR.TitleTree)) AS NVARCHAR(MAX)), CAST(LTRIM(RTRIM(DR.TitleIdTree)+' > '+LTRIM(RTRIM(E.EmployeeID))) AS NVARCHAR(MAX)), DR.Level -1 FROM Employees AS E 
JOIN DirectReports AS DR ON E.EmployeeID = DR.ManagerID
)

SELECT * FROM DirectReports e
ORDER BY e.Level