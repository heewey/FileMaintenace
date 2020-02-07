#Requires -Version 3.0

<#
.SYNOPSIS
arcserveUDP ver.6以降で実装されたCLI経由でバックアップジョブを起動するプログラムです。
実行にはCommonFunctions.ps1が必要です。
セットで開発しているFileMaintenance.ps1と併用すると複数の処理を一括実行できます。

<Common Parameters>はサポートしていません

.DESCRIPTION
arcserveUDP CLI経由でバックアップジョブを起動するプログラムです。
バックアップはフルバックアップ、差分バックアップを選択できます。
認証はパスワード平文、パスワードファイル、両方をサポートしています。
パスワードファイルを用いる場合、実行ユーザはパスワードを作成したユーザと同一にする必要があります。これはWindowsOSの仕様です。
例えば設定ファイルで$ExecUserを'arcserve'とし、プログラムを実行しているユーザが異なる場合はパスワードファイルを'arcserve'ユーザで作成しても認証する事は出来ません。
ジョブスケジューラ等で実行する時のユーザを'arcserve'として実行して下さい。

このプログラムとバックアップコンソールサーバとは同一または異なるホスト、両方をサポートしています。
バックアップコンソールをCPUコア数の多いバックアップサーバに搭載した場合、大量のジョブスケジューラライセンスが必要ですが、異なるホストに当プログラムを配置する事でライセンスを節約可能です。

ログ出力先は[Windows EventLog][コンソール][ログファイル]が選択可能です。それぞれ出力、抑止が指定できます。

ファイル配置例

D:\script\infra\arcserveUDPBackUp.ps1
D:\script\infra\Log\backup.flg
D:\script\infra\UDP.psw




---



.EXAMPLE

arcserveUDPBackUp.ps1 -Plan SSDB -Server SVDB01 -BackUpJobType Incr
arcserveUDPのバックアッププラン[SSDB]に含まれる、サーバ[SVDB01]を差分バックアップ起動します。

.EXAMPLE

arcserveUDPBackUp.ps1 -Plan SSDB -AllServers -BackUpJobType Full -UDPConsoleServerName BKUPSV01.corp.local
arcserveUDPのバックアッププラン[SSDB]に含まれる、全てのサーバをフルバックアップ起動します。
arcserveUDPのコンソールサーバはBKUPSV01.corp.localを指定します。

.EXAMPLE

arcserveUDPBackUp.ps1 -Plan SSDB -Server SVDB02 -BackUpJobType Incr -AuthorizationType PlainText -ExecUser = 'arcserve' -ExecUserDomain = 'INTRA' -ExecUserPassword = 'hogehoge'
arcserveUDPのバックアッププラン[SSDB]に含まれる、サーバ[SVDB02]を差分バックアップ起動します。
認証方式は平文パスワードとします。
バックアップコンソールサーバの管理ユーザはドメインユーザINTRA\arcserve、パスワードはhogehogeを指定します。
認証方式を平文パスワードとした場合、このプログラムを実行しているユーザと異なるユーザを指定する事が出来ます。


.EXAMPLE

arcserveUDPBackUp.ps1 -Plan SSDB -AllServers -BackUpJobType Full -AuthorizationType JobExecUserAndPasswordFile -ExecUserPasswordFilePath '.\UDP.psw'
arcserveUDPのバックアッププラン[SSDB]に含まれる、全てのサーバをフルバックアップ起動します。
認証方式はジョブ実行ユーザとパスワードファイルとします。ジョブ実行ユーザでバックアップコンソールサーバにログオンします。
この時のパスワードは予めジョブ実行ユーザのパスワードファイルを作成しておく必要があります。
パスワードファイルは指定したファイル名UDP.pswを自動変換します。
このプログラムを実行するユーザがDomain\arcserveの時には、ファイル名本体にアンダースコア'_'に続いてユーザ名[arcserve]を自動的に付加したファイル名UDP_arcserve.pswを読み込み、パスワードファイルとして使用します。


.PARAMETER Plan
arcserveUDPに登録してあるプラン名を指定します。
指定は必須です。

ワイルドカード*は使用できません。

.PARAMETER Server
arcserveUDPに登録してあるプランに含まれるサーバ名を1台分指定します。
プランに含まれないサーバは指定できません。
ワイルドカード*は使用できません。

.PARAMETER AllServers
arcserveUDPに登録してあるプランに含まれるサーバ全てをバックアップ対象にします。

.PARAMETER BackUpJobType
対象のバックアップ方式をしています。

Full:フルバックアップ
Incr:増分バックアップ




.PARAMETER BackupFlagFilePath = '.\SC_Logs\BackUp.flg' ,
バックアップ中を示すバックアップファイルの保存先パスを指定します。
ファイル名.拡張子で指定しますが、ファイル名に自動的に_Plan名_バックアップ対象サーバ名を付加したファイル名で保存します。
AllServersを指定した場合、バックアップサーバ名はAllとなります。


.PARAMETER PROTOCOL
arcserveUDPコンソールサーバにログオンする時のプロトコルを指定します。
http / httpsを指定してください。
デフォルトはhttpです。

.PARAMETER UDPConsolePort
arcserveUDPコンソールサーバにログオンする時の通信ポート番号を指定します。
デフォルトは8015です。


.PARAMETER UDPCLIPath
arcserveUDP CLIが配置されたパスを指定します。
相対、絶対パスで指定可能です。


.PARAMETER AuthorizationType
arcserveUDPコンソールサーバにログオンする認証方式を指定します。

JobExecUserAndPasswordFile:本プログラムを実行しているユーザ / 本プログラムを実行しているユーザ名を含むパスワードファイル
FixedPasswordFile:指定したユーザ / 指定したパスワードファイル
PlanText:指定したユーザ / 平文パスワード

.PARAMETER ExecUser
認証方式をPlainText , FixedPasswordFileとした時のarcserveUDPコンソールサーバログオンのOSユーザ名を指定します。
ドメインユーザの場合、ドメイン部分を除去したものを指定してください。

例:FooDOMAIN\BarUSERであれば、BarUSER


.PARAMETER ExecUserDomain
認証方式をPlainText , FixedPasswordFileとした時のarcserveUDPコンソールサーバログオンOSユーザのドメイン名を指定します。

例:FooDOMAIN\BarUSERであれば、FooDOMAIN

.PARAMETER ExecUserPassword
認証方式をPlainTextとした時のarcserveUDPコンソールサーバログオンOSユーザのパスワードを平文で指定します。


.PARAMETER FixedPasswordFilePath
認証方式をFixedPasswordFileとした時のarcserveUDPコンソールサーバログオンOSユーザのパスワードファイルを指定します。



.PARAMETER ExecUserPasswordFilePath
認証方式をJobExecUserAndPasswordFileとした時のarcserveUDPコンソールサーバログオンOSユーザのパスワードファイルパスを指定します。

例:'.\UDP.psw' , 本プログラムを実行しているユーザがFooDOMAIN\BarUSER
'.UDP_BarUSER.psw'がパスワードファイルとして指定されます。
アンダースコア_以降の部分は実行しているユーザ名が自動的に挿入されます。


.PARAMETER UDPConsoleServerName
arcserveUDPコンソールサーバのホスト名、IPアドレスを指定します。



.PARAMETER Log2EventLog
　Windows Event Logへの出力を制御します。
デフォルトは$TRUEでEvent Log出力します。

.PARAMETER NoLog2EventLog
　Event Log出力を抑止します。-Log2EventLog $Falseと等価です。

.PARAMETER ProviderName
　Windows Event Log出力のプロバイダ名を指定します。デフォルトは[Infra]です。

.PARAMETER EventLogLogName
　Windows Event Log出力のログ名をしています。デフォルトは[Application]です。

.PARAMETER Log2Console 
　コンソールへのログ出力を制御します。
デフォルトは$TRUEでコンソール出力します。

.PARAMETER NoLog2Console
　コンソールログ出力を抑止します。-Log2Console $Falseと等価です。

.PARAMETER Log2File
　ログフィルへの出力を制御します。デフォルトは$Falseでログファイル出力しません。

.PARAMETER NoLog2File
　ログファイル出力を抑止します。-Log2File $Falseと等価です。

.PARAMETER LogPath
　ログファイル出力パスを指定します。デフォルトは$NULLです。
相対、絶対パスで指定可能です。
相対パス表記は、.から始める表記にして下さい。（例 .\Log\Log.txt , ..\Script\log\log.txt）
ワイルドカード* ? []は使用できません。
フォルダ、ファイル名に括弧 [ , ] を含む場合はエスケープせずにそのまま入力してください。
ファイルが存在しない場合は新規作成します。
ファイルが既存の場合は追記します。

.PARAMETER LogDateFormat
　ログファイル出力に含まれる日時表示フォーマットを指定します。デフォルトは[yyyy-MM-dd-HH:mm:ss]形式です。

.PARAMETER NormalReturnCode
　正常終了時のリターンコードを指定します。デフォルトは0です。正常終了=<警告終了=<（内部）異常終了として下さい。

.PARAMETER WarningReturnCode
　警告終了時のリターンコードを指定します。デフォルトは1です。正常終了=<警告終了=<（内部）異常終了として下さい。

.PARAMETER ErrorReturnCode
　異常終了時のリターンコードを指定します。デフォルトは8です。正常終了=<警告終了=<（内部）異常終了として下さい。

.PARAMETER InternalErrorReturnCode
　プログラム内部異常終了時のリターンコードを指定します。デフォルトは16です。正常終了=<警告終了=<（内部）異常終了として下さい。

.PARAMETER InfoEventID
　Event Log出力でInformationに対するEvent IDを指定します。デフォルトは1です。

.PARAMETER WarningEventID
　Event Log出力でWarningに対するEvent IDを指定します。デフォルトは10です。

.PARAMETER SuccessErrorEventID
　Event Log出力でSuccessに対するEvent IDを指定します。デフォルトは73です。

.PARAMETER InternalErrorEventID
　Event Log出力でInternal Errorに対するEvent IDを指定します。デフォルトは99です。

.PARAMETER ErrorEventID
　Event Log出力でErrorに対するEvent IDを指定します。デフォルトは100です。

.PARAMETER ErrorAsWarning
　異常終了しても警告終了のReturnCodeを返します。

.PARAMETER WarningAsNormal
　警告終了しても正常終了のReturnCodeを返します。

.PARAMETER ExecutableUser
　このプログラムを実行可能なユーザを正規表現で指定します。
デフォルトは[.*]で全てのユーザが実行可能です。　
記述はシングルクオーテーションで括って下さい。
正規表現のため、ドメインのバックスラッシュは[domain\\.*]の様にバックスラッシュでエスケープして下さい。　


#>

Param(

[String][parameter(mandatory=$true)]$Plan ,
[String]$Server = 'hoge-hoge',
[Switch]$AllServers,
[String][ValidateSet("Full", "Incr")]$BackUpJobType = 'Incr',

[String]$BackupFlagFilePath = '.\SC_Logs\BackUp.flg' ,


[String][ValidateSet("http", "https")]$PROTOCOL = 'http' ,
[int]$UDPConsolePort = 8015 ,

[String]$UDPCLIPath = 'D:\arcserve\Management\PowerCLI\UDPPowerCLI.ps1',

[String]$ExecUser = 'arcserve',
[String]$ExecUserDomain = 'PNX',
[String]$ExecUserPassword = 'hogehoge',
[String]$ExecUserPasswordFilePath = '.\UDP.psw' ,
[String]$FixedPasswordFilePath = '.\UDP_arcserve.psw' ,

[String][ValidateSet("JobExecUserAndPasswordFile","FixedPasswordFile" , "PlainText")]$AuthorizationType = 'PlainText' ,

[String]$UDPConsoleServerName = 'localhost' ,



[boolean]$Log2EventLog = $TRUE,
[Switch]$NoLog2EventLog,
[String]$ProviderName = "Infra",
[String][ValidateSet("Application")]$EventLogLogName = 'Application',

[boolean]$Log2Console = $TRUE,
[Switch]$NoLog2Console,
[boolean]$Log2File = $False,
[Switch]$NoLog2File,
[String][ValidatePattern('^(\.+\\|[c-zC-Z]:\\)(?!.*(\/|:|\?|`"|<|>|\||\*)).*$')]$LogPath ,
#[String][ValidatePattern('^(\.+\\|[c-zC-Z]:\\).*')]$LogPath = ..\Log\FileMaintenance.log ,
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

IF(-NOT($AllServers)){

    CheckHostname -CheckHostName $Server -ObjectName 'バックアップ対象 -Server' > $NULL
    }

    CheckHostname -CheckHostName $UDPConsoleServerName -ObjectName 'arcserveUDP Console Server -UDPConsoleServerName' > $NULL

#[String][ValidateSet("JobExecUserAndPasswordFile","FixedPasswordFile" , "PlanText")]$AuthorizationType = 'JobExecUserAndPasswordFile' ,


IF($AuthorizationType -match '^(FixedPasswordFile|PlainText)$' ){

    CheckDomainName -CheckDomainName $ExecUserDomain -ObjectName '実行ユーザが所属するドメイン -ExecUserDomain'  > $NULL
    
    CheckUserName -CheckUserName $ExecUser -ObjectName '実行ユーザ -ExecUser ' > $NULL

    }

#UDPConsoleの存在を確認

    IF(Test-Connection -ComputerName $UDPConsoleServerName -Quiet){
    
    Logging -EventID $SuccessEventID -EventType Success -EventMessage "UDPコンソールサーバ[$($UDPConsoleServerName)]が応答しました。"
    }else{
    Logging -EventID $ErrorEventID -EventType Error -EventMessage "UDPコンソールサーバ[$($UDPConsoleServerName)]が応答しません。 -UDPConsoleServerNameが正しく設定されているか確認して下さい。"
    Exit $ErrorReturnCode
    }


#Password Fileの有無を確認

IF($AuthorizationType -match '^FixedPasswordFile$' ){

    $FixedPasswordFilePath  = ConvertToAbsolutePath -CheckPath $FixedPasswordFilePath -ObjectName '-FixedPasswordFilePath'

    CheckLeaf -CheckPath $FixedPasswordFilePath -ObjectName '-FixedPasswordFilePath' -IfNoExistFinalize > $NULL
    }

IF($AuthorizationType -match '^JobExecUserAndPasswordFile$' ){

    $ExecUserPasswordFilePath  = ConvertToAbsolutePath -CheckPath $ExecUserPasswordFilePath -ObjectName '-ExecUserPasswordFilePath'
    
    CheckContainer -CheckPath (Split-Path -Parent -Path $ExecUserPasswordFilePath) -ObjectName '-ExecUserPasswordFilePathの親フォルダ'  -IfNoExistFinalize > $NULL

    }

    $BackupFlagFilePath  = ConvertToAbsolutePath -CheckPath $BackupFlagFilePath -ObjectName '-BackupFlagFilePath'
    
    CheckContainer -CheckPath (Split-Path -Parent -Path $BackupFlagFilePath) -ObjectName '-BackupFlagFilePathの親フォルダ'  -IfNoExistFinalize > $NULL


#arcserveUDP CLIの有無を確認
    

    $UDPCLIPath = ConvertToAbsolutePath -CheckPath $UDPCLIPath -ObjectName 'arcserveUDP CLI -UDPCLIPath'

    CheckLeaf -CheckPath $UDPCLIPath -ObjectName 'arcserveUDP CLI -UDPCLIPath' -IfNoExistFinalize > $NULL



#処理開始メッセージ出力


Logging -EventID $InfoEventID -EventType Information -EventMessage "パラメータは正常です"

Logging -EventID $InfoEventID -EventType Information -EventMessage "arcserve UDPバックアップ　方式[$($BackUpJobType)]を開始します"

}

function GetUserAndDomain{

$UserInfo = @()

#ユーザ名はdomain\userの形式で出力されるので、バックスラッシュ\を区切り記号として、配列に代入
#-Splitは正規表現なのでエスケープ記号はバックスラッシュ\　Powershellのエスケープであるバッククオート`ではない

$UserInfo = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name -split '\\'


$Script:DoDomain = $UserInfo[0]
$Script:DoUser = $UserInfo[1]

}



function Finalize {

Param(
[parameter(mandatory=$true)][int]$ReturnCode
)

    IF(CheckLeaf -CheckPath $BackupFlagFilePath -ObjectName 'BackUp Flag'){
        TryAction -ActionType Delete -ActionFrom  $BackupFlagFilePath -ActionError "BackUp Flag [$($BackupFlagFilePath)]"
        }

    IF(-NOT(($NormalCount -eq 0) -and ($WarningCount -eq 0) -and ($ErrorCount -eq 0))){

        Logging -EventID $InfoEventID -EventType Information -EventMessage "実行結果は正常終了[$($NormalCount)]、警告終了[$($WarningCount)]、異常終了[$($ErrorCount)]です"

        If(($Continue) -and ($ErrorCount -gt 0)){
            Logging -EventID $InfoEventID -EventType Information -EventMessage "-Continue[${Continue}]が指定されているため処理異常で異常終了せず次の定義を処理しました"
            }


    }


EndingProcess $ReturnCode



}



#####################   ここから本体  ######################


[int][ValidateRange(0,2147483647)]$NormalCount = 0
[int][ValidateRange(0,2147483647)]$WarningCount = 0
[int][ValidateRange(0,2147483647)]$ErrorCount = 0

$Version = '20200207_1615'
 

#初期設定、パラメータ確認、起動メッセージ出力

. Initialize

. GetUserAndDomain


       $Command = "$UDPCLIPath -UDPConsoleServerName $UDPConsoleServerName -Command Backup -BackupJobType $BackUpJobType -UDPConsoleProtocol $PROTOCOL -UDPConsolePort $UDPConsolePort -AgentBasedJob False"


IF($AllServers){

       Logging -EventID $InfoEventID -EventType Information -EventMessage "バックアップはプラン[$($Plan)]に含まれる全サーバが対象です。"
       $Command +=  " -PlanName $Plan "
       $Server = 'All'
       }
       else{
      Logging -EventID $InfoEventID -EventType Information -EventMessage "バックアップはプラン[$($Plan)]に含まれるサーバ[$($Server)]が対象です。"    

      $Command += " -NodeName $Server "

       }



Switch -Regex ($AuthorizationType){

    '^JobExecUser$'
        {
        #今のところ、この認証方式はarcserve UDPでは出来ない。実行ユーザが権限を持っていても(パスワードファイル|パスワード)を与える必要がある
        Logging -EventID $InfoEventID -EventType Information -EventMessage "認証方法は[$($AuthorizationType)]です。ジョブ実行中ユーザ名と認証情報で認証します。"
        }
    '^JobExecUserAndPasswordFile$'
        {
        Logging -EventID $InfoEventID -EventType Information -EventMessage "認証方法は[$($AuthorizationType)]です。ジョブ実行中ユーザ名、予め用意した実行ユーザ名を含むパスワードファイルで認証します。"
        $ExecUserPasswordFileName = Split-Path -Path $ExecUserPasswordFilePath -Leaf 
        $ExtensionString = [System.IO.Path]::GetExtension($ExecUserPasswordFileName)
        $FileNameWithOutExtentionString = [System.IO.Path]::GetFileNameWithoutExtension($ExecUserPasswordFileName)
        $ExecUserPasswordFileName = $FileNameWithOutExtentionString + "_"+$DoUser+$ExtensionString
        
        $ExecUserPasswordFilePath = Join-Path (Split-Path -Path $ExecUserPasswordFilePath -Parent ) $ExecUserPasswordFileName

        CheckLeaf -CheckPath $ExecUserPasswordFilePath -ObjectName '-ExecUserPasswordFilePath' -IfNoExistFinalize > $NULL

        $Command += " -UDPConsoleUserName `'$DoUser`' -UDPConsoleDomainName `'$DoDomain`' -UDPConsolePasswordFile `'$ExecUserPasswordFilePath`' "
        }

    '^FixedPasswordFile$'
        {
        Logging -EventID $InfoEventID -EventType Information -EventMessage "認証方法は[$($AuthorizationType)]です。指定したユーザ名、予め用意したパスワードファイルで認証します。"
        $Command += "-UDPConsoleDomainName `'$ExecUserDomain`' -UDPConsoleUserName `'$ExecUser`' -UDPConsolePasswordFile `'$FixedPasswordFilePath`' "
        }
    '^PlainText$'
        {
        Logging -EventID $InfoEventID -EventType Information -EventMessage "認証方法は[$($AuthorizationType)]です。指定したユーザ名、指定した平文パスワードで認証します。。"
        $Command += "-UDPConsoleDomainName `'$ExecUserDomain`' -UDPConsoleUserName `'$ExecUser`' -UDPConsolePassword `'$ExecUserPassword`' "
        }
    Default
        {
        Logging -EventID $InternalErrorEventID -EventType Error -EventMessage "内部エラー。-AuthorizationTypeの指定が正しくありません"
        Finalize $ErrorReturnCode
        }
}

        $BackupFlagFileName = Split-Path -Path $BackupFlagFilePath -Leaf 
        $ExtensionString = [System.IO.Path]::GetExtension($BackupFlagFileName)
        $FileNameWithOutExtentionString = [System.IO.Path]::GetFileNameWithoutExtension($BackupFlagFileName)
        $BackupFlagFileName = $FileNameWithOutExtentionString + "_"+$Plan+"_"+$Server+$ExtensionString
        
        $BackupFlagFilePath = Join-Path (Split-Path -Path $BackupFlagFilePath -Parent ) $BackupFlagFileName



IF(CheckLeaf -CheckPath $BackupFlagFilePath -ObjectName 'バックアップ実行中フラグ'){

            Logging -EventID $ErrorEventID -EventType Error -EventMessage "Back Up実行中です。重複実行は出来ません"
            Finalize $ErrorReturnCode
            }

CheckLogPath -CheckPath $BackupFlagFilePath -ObjectName 'バックアップ実行中フラグ格納フォルダ'



        Logging -EventID $InfoEventID -EventType Information -EventMessage "arcserveUDP CLI [$($UDPCLIPath)]を起動します"

        Try{


         $Return = Invoke-Expression $Command 2>$ErrorMessage -ErrorAction Stop
        
        }
        catch [Exception]{

            Logging -EventID $ErrorEventID -EventType Error -EventMessage "arcserveUDP CLI [$($UDPCLIPath)]の起動に失敗しました。"
            $ErrorDetail = $Error[0] | Out-String
            Logging -EventID $ErrorEventID -EventType Error -EventMessage "起動時エラーメッセージ : $ErrorDetail"
            Finalize $ErrorReturnCode
        }


        IF ($Return -ne 0){
                   
        Logging -EventID $ErrorEventID -EventType Error -EventMessage "[$($Plan)]に含まれるサーバ[$($Server)]のバックアップ方式[$($BackUpJobType)]に失敗しました。"
        Logging -EventID $ErrorEventID -EventType Error -EventMessage "Error Message [$($ErrorMessage)]"

        Finalize $ErrorReturnCode         
        }

Logging -EventID $SuccessEventID -EventType Success -EventMessage "[$($Plan)]に含まれるサーバ[$($Server)]のバックアップ方式[$($BackUpJobType)]の開始に成功しました。"

Finalize $NormalReturnCode