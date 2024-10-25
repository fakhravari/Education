

Declare @database nvarchar(1000)
Declare @tsql nvarchar(4000)
Declare DatabaseCursor Cursor
Local
Static
For
select name from master.dbo.sysdatabases
open DatabaseCursor
fetch next from DatabaseCursor into @database

while @@fetch_status = 0
begin
 print 'database:' + @database
 if @database not in ('tempdb','master','model','msdb')
 begin
  SET @tsql = 'use master;
     alter database ['+@database+'] set offline with rollback immediate;
     alter database ['+@database+'] set online; 
   DECLARE @dbLogName nvarchar(500) ;  
   Use  ['+@database+']  ;
   select @dbLogName = rtrim(ltrim(name)) from sysfiles WHERE FILEID=2;
   ALTER DATABASE ['+@database+'] SET RECOVERY SIMPLE;
   ALTER DATABASE ['+@database+'] SET SINGLE_USER ; 
   DBCC SHRINKFILE(@dbLogName , 2) ;   
   ALTER DATABASE ['+@database+'] SET MULTI_USER ;
   ALTER DATABASE ['+@database+'] SET RECOVERY FULL;' 
   EXEC(@tsql)
 end
 fetch next from DatabaseCursor into @database
end

close DatabaseCursor

deallocate DatabaseCursor