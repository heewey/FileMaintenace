﻿#Requires -Version 3.0

$Script:SQLsVersion = '20200117_1120'

[String]$DBStart = @'

WHENEVER SQLERROR EXIT 1
startup
exit
'@


[String]$DBMount = @'
alter database mount;
exit
'@

[String]$DBOpen = @'
alter database open;
exit
'@


[String]$DBStatus = @'

WHENEVER SQLERROR EXIT 1
select STATUS from v$instance;
exit

'@

[String]$DBShutDown = @'

WHENEVER SQLERROR EXIT 1
alter session set events 'immediate trace name systemstate level 266'; 
alter session set events 'immediate trace name systemstate level 266'; 
alter session set events 'immediate trace name systemstate level 266';  
shutdown immediate;
exit
'@



[String]$DBExportControlFile = @"

WHENEVER SQLERROR EXIT 1
alter database backup controlfile to '&controlfiledotctlPATH';
alter database backup controlfile to trace as '&controlfiledotbkPATH';
exit

"@


[String]$DBCheckBackUpMode = @'

WHENEVER SQLERROR EXIT 1
select * from v$backup status;
exit

'@


[String]$DBBackUpModeOn = @'

WHENEVER SQLERROR EXIT 1
alter database begin backup;
select * from v$backup status;
exit

'@



[String]$DBBackUpModeOff = @'

WHENEVER SQLERROR EXIT 1
alter database end backup;
select * from v$backup status;
exit

'@

[String]$RegistListener = @'

alter system register;
exit

'@

[String]$SessionCheck = @'

SELECT sid,serial#,username,status,machine,program,sql_id FROM v$session WHERE username IS NOT NULL and sid != USERENV('SID');
exit

'@


[String]$ExportRedoLog = @'

WHENEVER SQLERROR EXIT 1
alter system archive log current;
exit

'@