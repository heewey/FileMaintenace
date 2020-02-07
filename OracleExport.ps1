#Requires -Version 3.0

Param(

[String]$ExecUser = 'foo',
[String]$ExecUserPassword = 'hogehoge',
[parameter(mandatory=$true , HelpMessage = 'Oracle Service(ex. MCDB) 全てのHelpはGet-Help FileMaintenance.ps1')][String]$OracleService ,
#[String]$OracleService = 'MCDB',

#[parameter(mandatory=$true)][String]$Schema  ,
[String]$Schema = 'MCFRAME' ,

[String]$HostName = $Env:COMPUTERNAME,

[String]$DumpDirectoryObject='MCFDATA_PUMP_DIR' ,

#[String]$OracleHomeBinPath = 'D:\TEST' ,
[String]$OracleHomeBinPath = $Env:ORACLE_HOME +'\BIN' ,

[Switch]$PasswordAuthorization ,

[String][ValidatePattern('^(?!.*(\\|\/|:|\?|`"|<|>|\|)).*$')]$TimeStampFormat = '_yyyyMMdd_HHmmss',

[String]$DumpFile = $HostName+"_"+$Schema+"_PUMP.dmp",
[String]$LogFile  = $HostName+"_"+$Schema+"_PUMP.log",

[Switch]$AddtimeStamp,


[boolean]$Log2EventLog = $TRUE,
[Switch]$NoLog2EventLog,
[String]$ProviderName = "Infra",
[String][ValidateSet("Application")]$EventLogLogName = 'Application',

[boolean]$Log2Console =$TRUE,
[Switch]$NoLog2Console,
[boolean]$Log2File = $False,
[Switch]$NoLog2File,
[String][ValidatePattern('^(\.+\\|[C-Z]:\\)(?!.*(\/|:|\?|`"|<|>|\|)).*$')]$LogPath ,
[String]$LogDateFormat = "yyyy-MM-dd-HH:mm:ss",
[String][ValidateSet("Default", "UTF8" , "UTF7" , "UTF32" , "Unicode")]$LogFileEncode = 'Default', #Default指定はShift-Jis

[int][ValidateRange(0,2147483647)]$NormalReturnCode = 0,
[int][ValidateRange(0,2147483647)]$WarningReturnCode = 1,
[int][ValidateRange(0,2147483647)]$ErrorReturnCode = 8,
[int][ValidateRange(0,2147483647)]$InternalErrorReturnCode = 16,

[int][ValidateRange(1,65535)]$InfoEventID = 1,
[int][ValidateRange(1,65535)]$WarningEventID = 10,
[int][ValidateRange(1,65535)]$SuccessEventID = 73,
[int][ValidateRange(1,65535)]$InternalErrorEventID = 99,
[int][ValidateRange(1,65535)]$ErrorEventID = 100,

[Switch]$ErrorAsWarning,
[Switch]$WarningAsNormal,

[Regex]$ExecutableUser ='.*'

)

################# CommonFunctions.ps1 Load  #######################

Try{

    #CommonFunctions.ps1の配置先を変更した場合は、ここを変更。同一フォルダに配置前提
    ."$PSScriptRoot\CommonFunctions.ps1"
    }
    Catch [Exception]{
    Write-Output "CommonFunctions.ps1 のLoadに失敗しました。CommonFunctions.ps1がこのファイルと同一フォルダに存在するか確認してください"
    Exit 1
    }


################ 設定が必要なのはここまで ##################

################# 共通部品、関数  #######################


function Initialize {

$SHELLNAME=Split-Path $PSCommandPath -Leaf
$THIS_PATH = $PSScriptRoot


#イベントソース未設定時の処理
#ログファイル出力先確認
#ReturnCode確認
#実行ユーザ確認
#プログラム起動メッセージ

. PreInitialize

#ここまで完了すれば業務的なロジックのみを確認すれば良い


#パラメータの確認

#指定フォルダの有無を確認

   $OracleHomeBinPath = ConvertToAbsolutePath -CheckPath $OracleHomeBinPath -ObjectName  '-OracleHomeBinPath'

   CheckContainer -CheckPath $OracleHomeBinPath -ObjectName '-OracleHomeBinPath' -IfNoExistFinalize > $NULL


        

#対象のOracleがサービス起動しているか確認

    $TargetOracleService = "OracleService"+$OracleService

    $ServiceStatus = CheckServiceStatus -ServiceName $TargetOracleService -Health Running

    IF (-NOT($ServiceStatus)){


        Logging -EventType Error -EventID $ErrorEventID -EventMessage "対象のOracleServiceが起動していません。"
        Finalize $ErrorReturnCode
        }else{
        Logging -EventID $InfoEventID -EventType Information -EventMessage "対象のOracle Serviceは正常に起動しています"
        }
     

#処理開始メッセージ出力


Logging -EventID $InfoEventID -EventType Information -EventMessage "パラメータは正常です"

Logging -EventID $InfoEventID -EventType Information -EventMessage "Oracle Data Pumpを開始します"

}

function Finalize {

Param(
[parameter(mandatory=$true)][int]$ReturnCode
)

Pop-Location

EndingProcess $ReturnCode


}

#####################   ここから本体  ######################

$Version = '20200207_1615'

$FormattedDate = (Get-Date).ToString($TimeStampFormat)

#初期設定、パラメータ確認、起動メッセージ出力

. Initialize



    IF($AddTimeStamp){

        $DumpFile = AddTimeStampToFileName -TimeStampFormat $TimeStampFormat -TargetFileName $DumpFile
        $LogFile = AddTimeStampToFileName -TimeStampFormat $TimeStampFormat -TargetFileName $LogFile

    }



    IF ($PasswordAuthorization){

        $ExecCommand = $ExecUser+"/"+$ExecUserPassword+"@"+$OracleService+" Directory="+$DumpDirectoryObject+" Schemas="+$Schema+" DumpFile="+$DumpFile+" LogFile="+$LogFile+" Reuse_DumpFiles=y"
    
    }else{

        $ExecCommand = "`' /@"+$OracleService+" as sysdba `' Directory="+$DumpDirectoryObject+" Schemas="+$Schema+" DumpFile="+$DumpFile+" LogFile="+$LogFile+" Reuse_DumpFiles=y "

    }

#echo $ExecCommand


#$ExecCommand = [ScriptBlock]::Create($ExecCommand)

#exit

# Invoke-NativeApplication -ScriptBlock $ExecCommand

Push-Location $OracleHomeBinPath

$Process = Start-Process .\expdp -ArgumentList $ExecCommand -Wait -NoNewWindow -PassThru 

#Invoke-NativeApplicationSafe -ScriptBlock $ExecCommand


IF ($Process.ExitCode -ne 0){


#IF ($LastExitCode -ne 0){

        Logging -EventID $ErrorEventID -EventType Error -EventMessage "Oracle Data Pumpに失敗しました"
	    Finalize $ErrorReturnCode



        }else{
        Logging -EventID $SuccessEventID -EventType Success -EventMessage "Oracle Data Pumpに成功しました"
        Finalize $NormalReturnCode
        }
                   

