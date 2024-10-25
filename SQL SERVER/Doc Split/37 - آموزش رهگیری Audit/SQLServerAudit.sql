--ساخت دیتابیس برای تست
USE master
GO
USE master 
IF DB_ID('AuditDB')>0 
BEGIN   
    ALTER DATABASE AuditDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE AuditDB
END   
CREATE DATABASE AuditDB
GO
USE AuditDB
GO
DROP TABLE IF EXISTS Employees
GO
CREATE TABLE Employees
(
	EmployeeID INT PRIMARY KEY,
	FirstName NVARCHAR(100),
	LastName NVARCHAR(100),
	EmployeeGroupCode TINYINT
)
GO
INSERT INTO Employees VALUES 
	(1,N'مسعود',N'طاهری',1),
	(2,N'فرید',N'طاهری',1),
	(3,N'مجید',N'طاهری',1),
	(4,N'علی',N'طاهری',1),
	(5,N'علیرضا',N'طاهری',2)
GO
SELECT * FROM Employees
GO
--------------------------------------------------------------------
--Server Audit ایجاد 
--Audit هدف مشخص کردن محل ذخیره سازی 
USE master 
GO  
--DROP SERVER AUDIT Audit_TestDB
GO
CREATE SERVER AUDIT Audit_TestDB
TO FILE
(
   FILEPATH=N'd:\Dump\trace',
   MAXSIZE=5 MB,
   MAX_ROLLOVER_FILES = 20 ,
   RESERVE_DISK_SPACE=OFF
)
WITH 
(
   QUEUE_DELAY=1000, -- مدت زمانی که آدیت می تواند برای یک دستور معطل شود
   ON_FAILURE=CONTINUE --اگر مشکلی هنگام ذخیره آدیت در روی دیسک بود چه کنم
)
GO
--Show Object Explorer
GO
SELECT * FROM SYS.server_audits
--Audit فایل های 
SELECT * FROM SYS.server_file_audits
GO
--------------------------------------------------------------------
--Database Audit Specification تست 
--در سطح دیتابیسAudit تعریف
USE AuditDB
GO   
CREATE DATABASE AUDIT SPECIFICATION DB_Audit_Employee
FOR SERVER AUDIT Audit_TestDB
	ADD (DELETE ON OBJECT::[dbo].Employees BY [public]),
	ADD (INSERT ON OBJECT::[dbo].Employees BY [public]),
	ADD (SELECT ON OBJECT::[dbo].Employees BY [public]),
	ADD (UPDATE ON OBJECT::[dbo].Employees BY [public])
WITH (STATE = ON)
GO
--ALTER DATABASE AUDIT SPECIFICATION DB_Audit_Employee WITH (STATE=OFF)
--DROP DATABASE AUDIT SPECIFICATION DB_Audit_Employee
GO
USE master
GO
--Enable Audit
ALTER SERVER AUDIT Audit_TestDB  WITH(STATE=ON)
GO
--View Audit Logs (Object Explorer)
GO
USE AuditDB
GO
--تست 
SELECT * FROM Employees
GO
INSERT INTO Employees VALUES 
	(6,N'محمد',N'مزیدی',3)
GO
UPDATE Employees SET FirstName+='*' WHERE EmployeeID=1
GO
DELETE Employees WHERE EmployeeID=6
GO
--Notepad مشاهده فایل در 
--استفاده از دستورات برای مشاهده فایل ها
SELECT 
      action_id,
      succeeded,
      session_id,
      session_server_principal_name,
      object_name,
      statement,
      file_name,
      audit_file_offset 
FROM sys.fn_get_audit_file('C:\Dump\Audit_TestDB_*.sqlaudit',DEFAULT,DEFAULT)
GO
SELECT 
	*
FROM sys.fn_get_audit_file('C:\Dump\Audit_TestDB_*.sqlaudit',DEFAULT,DEFAULT)
GO
--------------------------------------------------------------------
--غیر فعال + پاک کردن 
--Audit ,Database Audit Specification
USE AuditDB
GO   
ALTER DATABASE AUDIT SPECIFICATION DB_Audit_Employee 
WITH (STATE=OFF)
GO
DROP DATABASE AUDIT SPECIFICATION DB_Audit_Employee
GO   
USE master 
GO   
IF EXISTS(SELECT * FROM sys.server_audits WHERE name=N'Audit_TestDB')
BEGIN
   ALTER SERVER AUDIT Audit_TestDB WITH (STATE=OFF)
   DROP SERVER AUDIT Audit_TestDB
END   
GO
--------------------------------------------------------------------
--Server Audit Specification
-- هر فعالیتی به ازای ساخت و حذف لاگین ها انجام می شود ثبت شود
USE master
GO
CREATE SERVER AUDIT WriteToApplicationLog
TO APPLICATION_LOG --Target
WITH   
(
   QUEUE_DELAY=1500, 
   ON_FAILURE=CONTINUE 
)
GO
--Audit فعال کردن 
ALTER SERVER AUDIT WriteToApplicationLog  WITH(STATE=ON)
GO
SELECT * FROM SYS.server_audits
GO
--Audit فایل های 
SELECT * FROM SYS.server_file_audits
GO
CREATE SERVER AUDIT SPECIFICATION AuditDropCreateLogin
FOR SERVER AUDIT WriteToApplicationLog
	ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE=ON)
GO
--ایجاد لاگین 

--Event Viewer مشاهده در 
--EventID =33205
--------------------------------------------------------------------
--غیر فعال + پاک کردن 
--Audit ,Database Audit Specification
GO
ALTER SERVER AUDIT SPECIFICATION AuditDropCreateLogin WITH (STATE=OFF)
GO
DROP SERVER AUDIT SPECIFICATION AuditDropCreateLogin
GO
ALTER SERVER AUDIT WriteToApplicationLog WITH(STATE=OFF)
GO
DROP SERVER AUDIT WriteToApplicationLog
GO
--------------------------------------------------------------------
--Audit های مربوط به Action Group
--https://technet.microsoft.com/en-us/library/cc280663(SQL.100).aspx
GO