### Summary

A set of useful utility scripts written in Powershell for Microsoft Windows Platform.

##### FileMaintenance.ps1

Manage log and temp files with varios method including delete , copy , move , compress , archive , rename , nullclear , delete old generation and delete empty folders.
You can select files and folders with file size , number of days elapsed , regular expression , path regular expression.

At onece you can manage one folder. With Wrapper.ps1 you can manage multi folders.


##### StopService.ps1 / StartService.ps1

Start and stop Windows service.


##### MountDrive.ps1 / UnMountDrive.ps1

Mount and UnMount UNC path SMB file share.


##### OracleDB2BackUpMode.ps1 / OracleDB2NormalMode.ps1 / OracleArchiveLogDelete.ps1 / OracleExport.ps1

Start/stop Listener , change Oracle Mode (BackUp or Normal) , export control files.
After or before backup software execute , you run the script.


##### arcserveUDPbackup.ps1

Execute arcserveUDP CLI.


##### Wrapper.ps1

Execute .ps1 script with every line command in the command file like batch.


### Copyright

They are released under Apache License 2.0 , see [LICENSE](./License.txt)
