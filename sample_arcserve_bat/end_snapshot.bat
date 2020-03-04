@echo off

rem ---- スクリプトディレクトリ ----
set SC_DIR=%~dp0
set Myself_name=%~nx0

D:

cd D:\Scripts\Infra


set P_NAME=CheckFlag.ps1

powershell -Noninteractive -Command ".\CheckFlag.ps1 -FlagFolder .\Lock -FlagFile EndSnapshot.flg -CreateFlag ; exit $LASTEXITCODE"

	IF not %errorlevel%==0 (
		call %SC_DIR%MSGPRINT.bat %P_NAME%が異常終了しました。エラーレベル＝%errorlevel% ERROR 100
		goto :ERR
		)

exit /B

:ERR

exit /B 100