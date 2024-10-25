SELECT 
	ObjectName          = OBJECT_NAME(qt.objectid)
	,DiskReads          = qs.total_physical_reads -- The worst reads, disk reads
	,MemoryReads        = qs.total_logical_reads  --Logical Reads are memory reads
	,Executions         = qs.execution_count
	,AvgDuration        = qs.total_elapsed_time / qs.execution_count
	,CPUTime            = qs.total_worker_time
	,DiskWaitAndCPUTime = qs.total_elapsed_time
	,MemoryWrites       = qs.max_logical_writes
	,DateCached         = qs.creation_time
	,DatabaseName       = DB_Name(qt.dbid)
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE DB_Name(qt.dbid) = 'VatanBGS'
ORDER BY qs.total_elapsed_time DESC











SELECT TOP 100 *
FROM 
(
    SELECT
         DatabaseName       = DB_NAME(qt.dbid)
        ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
        ,DiskReads          = SUM(qs.total_physical_reads)   -- The worst reads, disk reads
        ,MemoryReads        = SUM(qs.total_logical_reads)    --Logical Reads are memory reads
        ,Total_IO_Reads     = SUM(qs.total_physical_reads + qs.total_logical_reads)
        ,Executions         = SUM(qs.execution_count)
        ,IO_Per_Execution   = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
        ,CPUTime            = SUM(qs.total_worker_time)
        ,DiskWaitAndCPUTime = SUM(qs.total_elapsed_time)
        ,MemoryWrites       = SUM(qs.max_logical_writes)
        ,DateLastExecuted   = MAX(qs.last_execution_time)
        
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    GROUP BY DB_NAME(qt.dbid), OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T WHERE T.DatabaseName='VatanBGS'
ORDER BY Total_IO_Reads DESC