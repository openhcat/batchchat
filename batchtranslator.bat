@echo off
setlocal enabledelayedexpansion

:: Translator engine runs silently in background alongside client
set "DB_ROOT=%~1"
set "USERNAME_FILE=%~2"

if "%DB_ROOT%"=="" exit /b
if "%USERNAME_FILE%"=="" exit /b

:SYNC_LOOP
if exist "%USERNAME_FILE%" (
    set /p "CURR_USER=" < "%USERNAME_FILE%"
    if not "!CURR_USER!"=="" (
        :: Update heartbeat timestamp
        echo !CURR_USER! - %date% %time% > "%DB_ROOT%\active_users_!CURR_USER!.tmp"
        move /y "%DB_ROOT%\active_users_!CURR_USER!.tmp" "%DB_ROOT%\active_users.txt" >nul 2>&1
    )
)

:: Poll shared folder changes every 3 seconds
ping -n 4 127.0.0.1 >nul
goto SYNC_LOOP
