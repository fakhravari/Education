SELECT 
     CPU            = SUM(cpu_time)
    ,WaitTime       = SUM(total_scheduled_time)
    ,ElapsedTime    = SUM(total_elapsed_time)
    ,Reads          = SUM(num_reads) 
    ,Writes         = SUM(num_writes) 
    ,Connections    = COUNT(1) 
    ,Program        = program_name
FROM sys.dm_exec_connections con
LEFT JOIN sys.dm_exec_sessions ses
    ON ses.session_id = con.session_id
GROUP BY program_name
ORDER BY cpu DESC






SELECT 
     CPU            = SUM(cpu_time)
    ,WaitTime       = SUM(total_scheduled_time)
    ,ElapsedTime    = SUM(total_elapsed_time)
    ,Reads          = SUM(num_reads) 
    ,Writes         = SUM(num_writes) 
    ,Connections    = COUNT(1) 
    ,[login]        = original_login_name
FROM sys.dm_exec_connections con
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = con.session_id
GROUP BY original_login_name
GO








SELECT
    SPID                = er.session_id
    ,STATUS             = ses.STATUS
    ,[Login]            = ses.login_name
    ,Host               = ses.host_name
    ,BlkBy              = er.blocking_session_id
    ,DBName             = DB_Name(er.database_id)
    ,CommandType        = er.command
    ,SQLStatement       = st.text
    ,ObjectName         = OBJECT_NAME(st.objectid)
    ,ElapsedMS          = er.total_elapsed_time
    ,CPUTime            = er.cpu_time
    ,IOReads            = er.logical_reads + er.reads
    ,IOWrites           = er.writes
    ,LastWaitType       = er.last_wait_type
    ,StartTime          = er.start_time
    ,Protocol           = con.net_transport
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads
    ,ClientAddress      = con.client_net_address
    ,Authentication     = con.auth_scheme
FROM sys.dm_exec_requests er
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
ON con.session_id = ses.session_id