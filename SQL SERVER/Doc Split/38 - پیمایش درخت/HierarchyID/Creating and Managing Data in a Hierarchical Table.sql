USE HR 
GO

DROP TABLE IF EXISTS EmployeeOrg


CREATE TABLE EmployeeOrg
(  EmployeeID int PRIMARY KEY NOT NULL,
   EmpName Nvarchar(20) NOT NULL,
   Title Nvarchar(50) NOT NULL,
   ManagerID INT NULL REFERENCES EmployeeOrg(EmployeeID), 
   
   OrgNode HIERARCHYID  NOT NULL UNIQUE,
   OrgNodeText AS OrgNode.ToString() PERSISTED,
   OrgLevel AS OrgNode.GetLevel() PERSISTED,

   ParentNode AS OrgNode.GetAncestor(1) PERSISTED REFERENCES EmployeeOrg(OrgNode),
) ;

GO

CREATE UNIQUE INDEX EmployeeOrgNc1 ON EmployeeOrg(OrgLevel, OrgNode) ;
GO


INSERT INTO EmployeeOrg (OrgNode, EmployeeID, EmpName, Title,ManagerID)
VALUES (hierarchyid::GetRoot(),1 , N'علی', N'مدیر عامل',NULL) ;

SELECT * FROM EmployeeOrg ;
GO

DECLARE @Manager hierarchyid 

SELECT @Manager = OrgNode
 FROM EmployeeOrg
 WHERE EmployeeID = 1 ;

INSERT EmployeeOrg (OrgNode, EmployeeID, EmpName, Title,ManagerID)
VALUES (@Manager.GetDescendant(NULL, NULL), 2, N'احمد', N'معاونت نرم افزار',1 ) ; 

SELECT * FROM EmployeeOrg ;
GO

CREATE OR ALTER PROC AddEmp(@mgrid int, @empid int, @emp_name Nvarchar(20), @title Nvarchar(50)) 
AS 
BEGIN
   DECLARE @mgrOrgNode hierarchyid, @lc hierarchyid -- Last Child
   
   SELECT @mgrOrgNode = OrgNode 
   FROM EmployeeOrg 
   WHERE EmployeeID = @mgrid;
   
   -- Serialize this process:
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
   
   BEGIN TRANSACTION
      -- find the orgNode of the last child of this manager:
      SELECT @lc = max(OrgNode) 
      FROM EmployeeOrg 
      WHERE OrgNode.GetAncestor(1) =@mgrOrgNode ;

      INSERT EmployeeOrg (OrgNode, EmployeeID, EmpName, Title,ManagerID)
      VALUES(@mgrOrgNode.GetDescendant(@lc, NULL), @empid, @emp_name, @title,@mgrid)
      
   COMMIT TRANSACTION
END ;
GO
--          ManagerID , EmployeeID , Name , Title
EXEC AddEmp 1, 3, N'حسین', N'معاونت پشتیبانی سیستم ها' ;
EXEC AddEmp 1, 4, N'تقی', N'معاونت فروش' ;
EXEC AddEmp 1, 5, N'جواد', N'معاونت اداری و مالی' ;

EXEC AddEmp 2, 6, N'اکبر', N'مدیر تحلیل سیستمها' ;
EXEC AddEmp 2, 7, N'زهرا', N'مدیر برنامه نویسی' ;

EXEC AddEmp 6, 8, N'مریم', N'سیستم آنالیست' ;
EXEC AddEmp 6, 9, N'کوروش', N'سیستم آنالیست' ;
EXEC AddEmp 6,10, N'شیرین', N'مستندساز' ;

EXEC AddEmp 7, 11, N'پیام', N'برنامه نویس' ;
EXEC AddEmp 7, 12, N'پیمان', N'برنامه نویس' ;
EXEC AddEmp 7, 13, N'رضا', N'برنامه نویس' ;

EXEC AddEmp 3, 14, N'داریوش', N'مدیر شبکه' ;
EXEC AddEmp 3, 15, N'کاوه', N'مدیر پشتیبانی' ;
EXEC AddEmp 3, 16, N'پرستو', N'مدیر بانک اطلاعاتی' ;


EXEC AddEmp 14, 17, N'اسد', N'تکنیسین شبکه' ;
EXEC AddEmp 14, 18, N'ساسان', N'تکنیسین شبکه' ;

EXEC AddEmp 15, 19, N'اکرم', N'پشتیبان سیستم فروش' ;
EXEC AddEmp 15, 20, N'حمید', N'پشتیبان سیستم مالی' ;
EXEC AddEmp 15, 21, N'محسن', N'پشتیبان سیستم تولید' ;
EXEC AddEmp 15, 22, N'محمد', N'پشتیبان سیستم انبار' ;

GO

SELECT *
FROM EmployeeOrg 
ORDER BY OrgNode ;-- Depth-First Order

SELECT *
FROM EmployeeOrg 
ORDER BY OrgLevel , OrgNode  ;-- Breath-First Order


------------------------------------------------------------------------------------------------

-- Querying a Hierarchical Table Using Hierarchy Methods:

-- To use GetRoot, and GetLevel 

SELECT  *
FROM EmployeeOrg
WHERE OrgNode = hierarchyid::GetRoot() ;

GO


-- Find the manager (Parent) of Ahmad (Software Manager EmpId=2) anf then all his subordinates: 

DECLARE @CurrentEmployee hierarchyid

SELECT @CurrentEmployee = OrgNode
FROM EmployeeOrg
WHERE EmployeeID = 2 ;

--SELECT @CurrentEmployee , @CurrentEmployee.ToString()

SELECT *
FROM EmployeeOrg
WHERE OrgNode = @CurrentEmployee.GetAncestor(1)   -- مدیر مستقیم این کارمند کیست؟

SELECT *
FROM EmployeeOrg
WHERE OrgNode.GetAncestor(1) = @CurrentEmployee   -- زیر دستان مستقیم یک کارمند

SELECT *
FROM EmployeeOrg
WHERE OrgNode.IsDescendantOf(@CurrentEmployee) = 1 ;  --  همه زیردستان یک کارمند
 
 
GO
 
-- You can also query for this information by using the GetAncestor method. 
-- GetAncestor takes an argument for the level that you are trying to return.

DECLARE @CurrentEmployee hierarchyid

SELECT @CurrentEmployee = OrgNode
FROM EmployeeOrg
WHERE EmployeeID = 1 ;

SELECT *
FROM EmployeeOrg
WHERE OrgNode.GetAncestor(2) = @CurrentEmployee

GO
---------------------------------------------------

-- GetDescendant Method ---

DECLARE @Manager hierarchyid, @Child1 hierarchyid, @Child2 hierarchyid

SELECT @Manager = CAST('/3/1/' AS hierarchyid)
SELECT @Child1  = CAST('/3/1/1/' AS hierarchyid)
SELECT @Child2  = CAST('/3/1/2/' AS hierarchyid)

SELECT @Manager.GetDescendant(@Child1, @Child2).ToString()
 

----------------------------------------------------

-- We want to move the Support Manager and his subordinates from under the System Support Director 
-- to the Software department using a SP:
GO

CREATE OR ALTER PROCEDURE MoveOrg(@ToBeMovedEmpID INT , @newMgrEmpID INT )
AS
BEGIN

DECLARE @nold hierarchyid = (SELECT OrgNode FROM EmployeeOrg WHERE EmployeeID = @ToBeMovedEmpID) ;
DECLARE @nnew hierarchyid = (SELECT OrgNode FROM EmployeeOrg WHERE EmployeeID = @newMgrEmpID) ;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

BEGIN TRANSACTION


DECLARE @MaxChild hierarchyid -- Max child of the new manager

SELECT @MaxChild= MAX(OrgNode) 
  FROM EmployeeOrg 
  WHERE OrgNode.GetAncestor(1) = @nnew ;
 
DECLARE @newOrg hierarchyid = @nnew.GetDescendant(@MaxChild, null)

 
UPDATE EmployeeOrg  
  SET OrgNode = OrgNode.GetReparentedValue(@nold, @newOrg)
  WHERE OrgNode.IsDescendantOf(@nold) = 1 ;

COMMIT TRANSACTION

END ;
GO
-- Now test the SP:
SELECT * FROM EmployeeOrg WHERE EmployeeID=15   -- /2/2/
SELECT * FROM EmployeeOrg WHERE EmployeeID=2    -- /1/

EXEC MoveOrg 15 , 2

SELECT * FROM EmployeeOrg ORDER BY OrgNode 
