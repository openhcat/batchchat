@echo off
title <batch>chat Client
color 09
setlocal enabledelayedexpansion
:: ===================================================
:: <BATCH>CHAT STARTUP SCREEN
:: ===================================================
cls
color 0B
echo.
echo   _  _   ___    _  _____  ___  _  _   ___  _  _   _  _____ 
echo  ^< \/ ^> ^| _ \  /_\^|_   _^|/ __^|^| _^| ^| / __^|^| _^| ^| /_\^|_   _^|
echo  ^|    ^| ^| _ \/ _ \ ^| ^| ^| (__ ^| _^| ^|^| (__ ^| _^| ^|/ _ \ ^| ^|  
echo  ^<_/\_^> ^|___/_/ \_\^|_^|  \___^|^|_^|^|_^| \___^|^|_^|^|_/_/ \_\^|_^|  
echo.
echo                   Starting ^<batch^>chat...
echo.
echo             (c) OpenHcat Projects. Licensed under the MIT license.
echo ===================================================
ping -n 3 127.0.0.1 >nul
cls
:: Load or Initialize Configuration
set "CONFIG_FILE=%~dp0client_config.ini"
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do set "%%A=%%B"
) else (
    cls
    echo ===================================================
    echo             WELCOME TO <batch>chat SETUP
    echo ===================================================
    set /p "DB_ROOT=Enter Path to Shared Folder: "
    echo DB_ROOT=!DB_ROOT!> "%CONFIG_FILE%"
)

:: Ensure DB directories exist
if not exist "%DB_ROOT%\users" mkdir "%DB_ROOT%\users"
if not exist "%DB_ROOT%\rooms" mkdir "%DB_ROOT%\rooms"
if not exist "%DB_ROOT%\dms" mkdir "%DB_ROOT%\dms"
if not exist "%DB_ROOT%\activity" mkdir "%DB_ROOT%\activity"

:: Authentication Check
if not exist "%~dp0current_user.dat" (
    call "%~dp0batchsignup.bat" "%DB_ROOT%"
)

set /p "CURR_USER=" < "%~dp0current_user.dat"
if "%CURR_USER%"=="" exit /b

:: Ensure user data files exist
if not exist "%DB_ROOT%\users\%CURR_USER%.followers" type nul > "%DB_ROOT%\users\%CURR_USER%.followers"
if not exist "%DB_ROOT%\users\%CURR_USER%.friends" type nul > "%DB_ROOT%\users\%CURR_USER%.friends"
if not exist "%DB_ROOT%\users\%CURR_USER%.requests" type nul > "%DB_ROOT%\users\%CURR_USER%.requests"

:: Start Background Sync Engine
start /min "" "%~dp0batchtranslator.bat" "%DB_ROOT%" "%~dp0current_user.dat"

:MAIN_HOME_MENU
set "ACT_COUNT=0"
if exist "%DB_ROOT%\activity\%CURR_USER%.act" (
    for /f %%A in ('type "%DB_ROOT%\activity\%CURR_USER%.act" ^| find /c /v ""') do set "ACT_COUNT=%%A"
)

cls
echo ===================================================
echo               ^<batch^>chat HUB [%CURR_USER%]
echo ===================================================
echo  [1] Chat Rooms Directory ^& Create Room
echo  [2] Direct Messages (DMs)
echo  [3] Friends List ^& Manage Requests
echo  [4] Activity Feed ^& Notifications (%ACT_COUNT%)
echo  [5] Public Profile Page Lookup
echo  [6] User Settings ^& Auto-Login
echo  [7] Exit Application
echo ===================================================
set /p "menu_choice=Select Option [1-7]: "

if "%menu_choice%"=="1" goto ROOMS_MENU
if "%menu_choice%"=="2" goto DMS_MENU
if "%menu_choice%"=="3" goto FRIENDS_MENU
if "%menu_choice%"=="4" goto ACTIVITY_FEED
if "%menu_choice%"=="5" goto PROFILE_PAGE
if "%menu_choice%"=="6" goto USER_SETTINGS
if "%menu_choice%"=="7" (
    taskkill /f /im cmd.exe /fi "WINDOWTITLE eq <batch>chat*" >nul 2>&1
    exit
)
goto MAIN_HOME_MENU

:ROOMS_MENU
cls
echo ===================================================
echo                 CHAT ROOMS DIRECTORY
echo ===================================================
echo Available Rooms:
for %%F in ("%DB_ROOT%\rooms\*.room") do (
    echo   - %%~nF
)
echo ---------------------------------------------------
echo  [1] Join Chat Room
echo  [2] Create New Chat Room
echo  [3] Back to Home
echo ===================================================
set /p "rchoice=Select [1-3]: "
if "%rchoice%"=="3" goto MAIN_HOME_MENU
if "%rchoice%"=="2" (
    for /f "tokens=1,2 delims==" %%A in (%DB_ROOT%\server_config.ini) do (
        if "%%A"=="ALLOW_ROOM_CREATION" set "RC_ALLOW=%%B"
    )
    if "!RC_ALLOW!"=="0" (
        echo [!] Room creation is disabled by the server admin.
        pause
        goto ROOMS_MENU
    )
    set /p "newroom=Enter New Room Name: "
    if not "!newroom!"=="" (
        echo [SYSTEM]: Room created by %CURR_USER% > "%DB_ROOT%\rooms\!newroom!.room"
        echo [OK] Room created!
    )
    timeout /t 2 >nul
    goto ROOMS_MENU
)
if "%rchoice%"=="1" (
    set /p "targetroom=Enter Room Name to Join: "
    if exist "%DB_ROOT%\rooms\%targetroom%.room" (
        goto CHAT_SESSION
    ) else (
        echo [!] Room not found!
        timeout /t 2 >nul
        goto ROOMS_MENU
    )
)
goto ROOMS_MENU

:CHAT_SESSION
cls
echo ===================================================
echo  CHAT ROOM: %targetroom% (Type /exit to leave)
echo ===================================================
type "%DB_ROOT%\rooms\%targetroom%.room"
echo ---------------------------------------------------
set /p "msg=Message: "
if /i "%msg%"=="/exit" goto ROOMS_MENU
echo [%CURR_USER%]: %msg% >> "%DB_ROOT%\rooms\%targetroom%.room"
goto CHAT_SESSION

:DMS_MENU
cls
echo ===================================================
echo                 DIRECT MESSAGES (DMs)
echo ===================================================
for /f "tokens=1,2 delims==" %%A in (%DB_ROOT%\server_config.ini) do (
    if "%%A"=="ALLOW_DMS" set "DM_ALLOW=%%B"
)
if "%DM_ALLOW%"=="0" (
    echo [!] Direct Messages are disabled by server admin.
    pause
    goto MAIN_HOME_MENU
)
set /p "dmuser=Enter Username for DM: "
if "%dmuser%"=="" goto MAIN_HOME_MENU

set "dm_file=%DB_ROOT%\dms\%CURR_USER%_%dmuser%.dm"
if not exist "%dm_file%" set "dm_file=%DB_ROOT%\dms\%dmuser%_%CURR_USER%.dm"

:DM_SESSION
cls
echo ===================================================
echo  DM WITH: %dmuser% (Type /exit to leave)
echo ===================================================
if exist "%dm_file%" type "%dm_file%"
echo ---------------------------------------------------
set /p "dmsg=Message: "
if /i "%dmsg%"=="/exit" goto MAIN_HOME_MENU
echo [%CURR_USER%]: %dmsg% >> "%dm_file%"
goto DM_SESSION

:FRIENDS_MENU
cls
echo ===================================================
echo                 FRIENDS ^& REQUESTS
echo ===================================================
echo Your Friends:
if exist "%DB_ROOT%\users\%CURR_USER%.friends" (
    type "%DB_ROOT%\users\%CURR_USER%.friends"
) else (
    echo   (No friends added yet)
)
echo ---------------------------------------------------
echo Pending Friend Requests:
if exist "%DB_ROOT%\users\%CURR_USER%.requests" (
    type "%DB_ROOT%\users\%CURR_USER%.requests"
) else (
    echo   (No pending requests)
)
echo ---------------------------------------------------
echo  [1] Accept a Friend Request
echo  [2] Interact with a Friend (Message / Profile / Block)
echo  [3] Back to Main Menu
echo ===================================================
set /p "fchoice=Select Option [1-3]: "

if "%fchoice%"=="3" goto MAIN_HOME_MENU

if "%fchoice%"=="1" (
    set /p "reqUser=Enter username to accept request from: "
    findstr /C:"%reqUser%" "%DB_ROOT%\users\%CURR_USER%.requests" >nul
    if !errorlevel! equ 0 (
        :: Remove from pending requests
        findstr /v /C:"%reqUser%" "%DB_ROOT%\users\%CURR_USER%.requests" > "%DB_ROOT%\users\%CURR_USER%.requests.tmp"
        move /y "%DB_ROOT%\users\%CURR_USER%.requests.tmp" "%DB_ROOT%\users\%CURR_USER%.requests" >nul
        
        :: Add to mutual friend lists
        echo %reqUser% >> "%DB_ROOT%\users\%CURR_USER%.friends"
        echo %CURR_USER% >> "%DB_ROOT%\users\%reqUser%.friends"
        
        echo [NOTIFICATION] %CURR_USER% accepted your friend request! >> "%DB_ROOT%\activity\%reqUser%.act"
        echo [OK] You are now friends with %reqUser%!
    ) else (
        echo [!] No pending request from that user.
    )
    timeout /t 2 >nul
    goto FRIENDS_MENU
)

if "%fchoice%"=="2" (
    set /p "friendTarget=Enter friend's username: "
    findstr /C:"!friendTarget!" "%DB_ROOT%\users\%CURR_USER%.friends" >nul
    if !errorlevel! equ 0 (
        :FRIEND_ACTION_MENU
        cls
        echo ===================================================
        echo  FRIEND: !friendTarget!
        echo ===================================================
        echo  [1] Message (DM)
        echo  [2] View Profile Page
        echo  [3] Block / Remove Friend
        echo  [4] Back
        echo ===================================================
        set /p "subF=Select [1-4]: "
        if "!subF!"=="4" goto FRIENDS_MENU
        if "!subF!"=="1" (
            set "dmuser=!friendTarget!"
            set "dm_file=%DB_ROOT%\dms\%CURR_USER%_!dmuser!.dm"
            if not exist "!dm_file!" set "dm_file=%DB_ROOT%\dms\!dmuser!_%CURR_USER%.dm"
            goto DM_SESSION
        )
        if "!subF!"=="2" (
            cls
            echo Profile: !friendTarget!
            echo ---------------------------------------------------
            if exist "%DB_ROOT%\users\!friendTarget!.page" type "%DB_ROOT%\users\!friendTarget!.page"
            echo ---------------------------------------------------
            pause
            goto FRIEND_ACTION_MENU
        )
        if "!subF!"=="3" (
            findstr /v /C:"!friendTarget!" "%DB_ROOT%\users\%CURR_USER%.friends" > "%DB_ROOT%\users\%CURR_USER%.friends.tmp"
            move /y "%DB_ROOT%\users\%CURR_USER%.friends.tmp" "%DB_ROOT%\users\%CURR_USER%.friends" >nul
            echo [OK] !friendTarget! removed from friends list.
            timeout /t 2 >nul
            goto FRIENDS_MENU
        )
    ) else (
        echo [!] User is not in your friends list.
        timeout /t 2 >nul
        goto FRIENDS_MENU
    )
)
goto FRIENDS_MENU

:ACTIVITY_FEED
cls
echo ===================================================
echo                ACTIVITY ^& NOTIFICATIONS
echo ===================================================
if exist "%DB_ROOT%\activity\%CURR_USER%.act" (
    type "%DB_ROOT%\activity\%CURR_USER%.act"
    del "%DB_ROOT%\activity\%CURR_USER%.act"
) else (
    echo No new notifications.
)
echo ---------------------------------------------------
pause
goto MAIN_HOME_MENU

:PROFILE_PAGE
cls
echo ===================================================
echo                 PUBLIC PROFILE PAGE
echo ===================================================
set /p "puser=Enter Username to View (Press Enter for yours): "
if "%puser%"=="" set "puser=%CURR_USER%"

if exist "%DB_ROOT%\users\%puser%.page" (
    cls
    echo ===================================================
    echo  Profile: %puser%
    echo ===================================================
    type "%DB_ROOT%\users\%puser%.page"
    echo ---------------------------------------------------
    echo Followers:
    if exist "%DB_ROOT%\users\%puser%.followers" (
        type "%DB_ROOT%\users\%puser%.followers"
    ) else (
        echo  (0 Followers)
    )
    echo ---------------------------------------------------
    echo Friends:
    if exist "%DB_ROOT%\users\%puser%.friends" (
        type "%DB_ROOT%\users\%puser%.friends"
    ) else (
        echo  (No friends listed)
    )
    echo ---------------------------------------------------
    echo  [1] Follow / Unfollow User
    echo  [2] Send Friend Request
    echo  [3] Back to Home Menu
    echo ===================================================
    set /p "pact=Select [1-3]: "
    if "%pact%"=="3" goto MAIN_HOME_MENU
    
    if "%pact%"=="1" (
        findstr /C:"%CURR_USER%" "%DB_ROOT%\users\%puser%.followers" >nul 2>&1
        if !errorlevel! equ 0 (
            findstr /v /C:"%CURR_USER%" "%DB_ROOT%\users\%puser%.followers" > "%DB_ROOT%\users\%puser%.followers.tmp"
            move /y "%DB_ROOT%\users\%puser%.followers.tmp" "%DB_ROOT%\users\%puser%.followers" >nul
            echo [OK] Unfollowed %puser%.
        ) else (
            echo %CURR_USER% >> "%DB_ROOT%\users\%puser%.followers"
            echo [NOTIFICATION] %CURR_USER% started following you! >> "%DB_ROOT%\activity\%puser%.act"
            echo [OK] Now following %puser%!
        )
        timeout /t 2 >nul
        goto MAIN_HOME_MENU
    )
    
    if "%pact%"=="2" (
        findstr /C:"%CURR_USER%" "%DB_ROOT%\users\%puser%.requests" >nul 2>&1
        if !errorlevel! neq 0 (
            echo %CURR_USER% >> "%DB_ROOT%\users\%puser%.requests"
            echo [NOTIFICATION] %CURR_USER% sent you a friend request! >> "%DB_ROOT%\activity\%puser%.act"
            echo [OK] Friend request sent to %puser%!
        ) else (
            echo [!] Request already pending.
        )
        timeout /t 2 >nul
        goto MAIN_HOME_MENU
    )
) else (
    echo [!] Profile not found.
    timeout /t 2 >nul
)
goto MAIN_HOME_MENU

:USER_SETTINGS
cls
echo ===================================================
echo                    USER SETTINGS
echo ===================================================
echo  [1] Edit Profile Page (Nickname, Bio, Socials)
echo  [2] Toggle Auto-Sign-In
echo  [3] Back to Main Menu
echo ===================================================
set /p "usign=Select [1-3]: "
if "%usign%"=="1" (
    set /p "nn=New Nickname: "
    set /p "bb=New Bio: "
    set /p "ss=New Social Links: "
    (
        echo NICKNAME=!nn!
        echo BIO=!bb!
        echo SOCIALS=!ss!
    ) > "%DB_ROOT%\users\%CURR_USER%.page"
    echo [OK] Profile updated!
    timeout /t 2 >nul
)
if "%usign%"=="2" (
    echo %CURR_USER% > "%~dp0autologin.dat"
    echo [OK] Auto-sign-in enabled!
    timeout /t 2 >nul
)
goto MAIN_HOME_MENU
