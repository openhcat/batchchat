@echo off
title <batch>chat - Server Dashboard
color 0A
setlocal enabledelayedexpansion

:: Define Database Root
set "DB_ROOT=%~dp0batchchat_shared"

:INIT_SERVER
if not exist "%DB_ROOT%" mkdir "%DB_ROOT%"
if not exist "%DB_ROOT%\users" mkdir "%DB_ROOT%\users"
if not exist "%DB_ROOT%\rooms" mkdir "%DB_ROOT%\rooms"
if not exist "%DB_ROOT%\dms" mkdir "%DB_ROOT%\dms"
if not exist "%DB_ROOT%\activity" mkdir "%DB_ROOT%\activity"
if not exist "%DB_ROOT%\bans" mkdir "%DB_ROOT%\bans"

:: Initialize Default Configuration if missing
if not exist "%DB_ROOT%\server_config.ini" (
    (
        echo ALLOW_SIGNUPS=1
        echo ALLOW_DMS=1
        echo ALLOW_ROOM_CREATION=1
    ) > "%DB_ROOT%\server_config.ini"
)

:: Initialize General Room if missing
if not exist "%DB_ROOT%\rooms\General.room" (
    echo [SYSTEM]: General Chat Room initialized. > "%DB_ROOT%\rooms\General.room"
)

:DASHBOARD_MENU
cls
echo ===================================================
echo               ^<batch^>chat SERVER DASHBOARD
echo ===================================================
echo  Shared Directory : %DB_ROOT%
echo  Status           : ONLINE (File-Based Engine)
echo ---------------------------------------------------
echo  [1] Server Settings ^& Toggles
echo  [2] User Management (Ban / Promote Admin)
echo  [3] View Active Users ^& Heartbeats
echo  [4] Purge / Reset Server Database
echo  [5] Exit Dashboard
echo ===================================================
set /p "choice=Select Option [1-5]: "

if "%choice%"=="1" goto SETTINGS_MENU
if "%choice%"=="2" goto USER_MGMT
if "%choice%"=="3" goto VIEW_ACTIVE
if "%choice%"=="4" goto RESET_DB
if "%choice%"=="5" exit
goto DASHBOARD_MENU

:SETTINGS_MENU
cls
echo ===================================================
echo                 SERVER SETTINGS
echo ===================================================
for /f "tokens=1,2 delims==" %%A in (%DB_ROOT%\server_config.ini) do (
    set "%%A=%%B"
)
echo  [1] Allow New Signups       : !ALLOW_SIGNUPS! (1=Yes, 0=No)
echo  [2] Allow Direct Messages   : !ALLOW_DMS! (1=Yes, 0=No)
echo  [3] Allow Room Creation     : !ALLOW_ROOM_CREATION! (1=Yes, 0=No)
echo  [B] Back to Main Menu
echo ---------------------------------------------------
set /p "tchoice=Toggle Setting [1-3 or B]: "
if /i "%tchoice%"=="B" goto DASHBOARD_MENU

if "%tchoice%"=="1" (
    if "!ALLOW_SIGNUPS!"=="1" (set "ALLOW_SIGNUPS=0") else (set "ALLOW_SIGNUPS=1")
)
if "%tchoice%"=="2" (
    if "!ALLOW_DMS!"=="1" (set "ALLOW_DMS=0") else (set "ALLOW_DMS=1")
)
if "%tchoice%"=="3" (
    if "!ALLOW_ROOM_CREATION!"=="1" (set "ALLOW_ROOM_CREATION=0") else (set "ALLOW_ROOM_CREATION=1")
)

(
    echo ALLOW_SIGNUPS=!ALLOW_SIGNUPS!
    echo ALLOW_DMS=!ALLOW_DMS!
    echo ALLOW_ROOM_CREATION=!ALLOW_ROOM_CREATION!
) > "%DB_ROOT%\server_config.ini"
goto SETTINGS_MENU

:USER_MGMT
cls
echo ===================================================
echo                  USER MANAGEMENT
echo ===================================================
echo Registered Users:
for %%F in ("%DB_ROOT%\users\*.usr") do (
    echo   - %%~nF
)
echo ---------------------------------------------------
set /p "target=Enter Username to Modify (or B to Back): "
if /i "%target%"=="B" goto DASHBOARD_MENU

if not exist "%DB_ROOT%\users\%target%.usr" (
    echo [!] User not found!
    timeout /t 2 >nul
    goto USER_MGMT
)

echo.
echo Selected User: %target%
echo [1] Ban / Unban User
echo [2] Promote to Admin / Demote to User
set /p "uact=Select Action [1-2]: "

if "%uact%"=="1" (
    findstr /C:"BANNED=1" "%DB_ROOT%\users\%target%.usr" >nul
    if !errorlevel! equ 0 (
        findstr /v "BANNED=" "%DB_ROOT%\users\%target%.usr" > "%DB_ROOT%\users\%target%.tmp"
        echo BANNED=0 >> "%DB_ROOT%\users\%target%.tmp"
        move /y "%DB_ROOT%\users\%target%.tmp" "%DB_ROOT%\users\%target%.usr" >nul
        echo [OK] User %target% unbanned.
    ) else (
        echo BANNED=1 >> "%DB_ROOT%\users\%target%.usr"
        echo [OK] User %target% banned.
    )
)
if "%uact%"=="2" (
    findstr /C:"ROLE=admin" "%DB_ROOT%\users\%target%.usr" >nul
    if !errorlevel! equ 0 (
        findstr /v "ROLE=" "%DB_ROOT%\users\%target%.usr" > "%DB_ROOT%\users\%target%.tmp"
        echo ROLE=user >> "%DB_ROOT%\users\%target%.tmp"
        move /y "%DB_ROOT%\users\%target%.tmp" "%DB_ROOT%\users\%target%.usr" >nul
        echo [OK] User %target% demoted to standard user.
    ) else (
        echo ROLE=admin >> "%DB_ROOT%\users\%target%.usr"
        echo [OK] User %target% promoted to ADMIN.
    )
)
timeout /t 2 >nul
goto USER_MGMT

:VIEW_ACTIVE
cls
echo ===================================================
echo              ACTIVE USERS HEARTBEAT
echo ===================================================
if exist "%DB_ROOT%\active_users.txt" (
    type "%DB_ROOT%\active_users.txt"
) else (
    echo No active user heartbeats recorded yet.
)
echo ---------------------------------------------------
pause
goto DASHBOARD_MENU

:RESET_DB
cls
echo ===================================================
echo [!] WARNING: THIS WILL WIPE ALL USERS, ROOMS, AND CHATS!
echo ===================================================
set /p "confirm=Type YES to confirm database reset: "
if "%confirm%"=="YES" (
    rmdir /s /q "%DB_ROOT%"
    echo Database cleared successfully.
    timeout /t 2 >nul
    goto INIT_SERVER
)
goto DASHBOARD_MENU
