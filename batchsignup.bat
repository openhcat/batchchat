@echo off
title <batch>chat - Authentication Portal
color 0B
setlocal enabledelayedexpansion

set "DB_ROOT=%~1"
if "%DB_ROOT%"=="" (
    set /p "DB_ROOT=Enter Path to <batch>chat Shared Folder: "
)

if not exist "%DB_ROOT%" (
    echo [!] Shared folder path does not exist!
    pause
    exit /b
)

:AUTH_MENU
cls
echo ===================================================
echo               ^<batch^>chat PORTAL
echo ===================================================
echo.
echo  [1] Sign In
echo  [2] Create New Account (Sign Up)
echo  [3] Exit
echo.
echo ===================================================
set /p "auth_choice=Select Option [1-3]: "

if "%auth_choice%"=="1" goto SIGN_IN
if "%auth_choice%"=="2" goto SIGN_UP
if "%auth_choice%"=="3" exit /b
goto AUTH_MENU

:SIGN_UP
:: Check if signups are allowed
for /f "tokens=1,2 delims==" %%A in (%DB_ROOT%\server_config.ini) do (
    if "%%A"=="ALLOW_SIGNUPS" set "ALLOW_SIGNUPS=%%B"
)
if "%ALLOW_SIGNUPS%"=="0" (
    cls
    echo [!] Signups are currently disabled by the server admin.
    pause
    goto AUTH_MENU
>nul

cls
echo ===================================================
echo                   ACCOUNT SIGN UP
echo ===================================================
echo.
echo  NOTICE: Passwords are not encrypted and stored!
echo  Please use a different password than other apps!
echo.
echo ---------------------------------------------------
set /p "username=Choose Username: "
set /p "password=Choose Password: "

if "%username%"=="" goto SIGN_UP
if "%password%"=="" goto SIGN_UP

if exist "%DB_ROOT%\users\%username%.usr" (
    echo [!] Username already taken!
    timeout /t 2 >nul
    goto SIGN_UP
)

:: Save user credentials (Base64 encoded via certutil for basic obfuscation)
echo %password% > "%TEMP%\pw.tmp"
certutil -encode "%TEMP%\pw.tmp" "%TEMP%\pw_enc.tmp" >nul
del "%TEMP%\pw.tmp"

(
    echo USERNAME=%username%
    echo ROLE=user
    echo BANNED=0
) > "%DB_ROOT%\users\%username%.usr"
type "%TEMP%\pw_enc.tmp" >> "%DB_ROOT%\users\%username%.usr"
del "%TEMP%\pw_enc.tmp"

:: Initialize default profile page
(
    echo NICKNAME=%username%
    echo BIO=Hello, I am using ^<batch^>chat!
    echo SOCIALS=None
    echo PROFILE_THEME=neon
) > "%DB_ROOT%\users\%username%.page"

echo [OK] Account created successfully!
timeout /t 2 >nul
goto SIGN_IN

:SIGN_IN
cls
echo ===================================================
echo                    SIGN IN
echo ===================================================
set /p "username=Username: "
set /p "password=Password: "

if not exist "%DB_ROOT%\users\%username%.usr" (
    echo [!] User does not exist!
    timeout /t 2 >nul
    goto AUTH_MENU
)

:: Check if banned
findstr /C:"BANNED=1" "%DB_ROOT%\users\%username%.usr" >nul
if !errorlevel! equ 0 (
    echo [!] Your account has been BANNED from this server.
    pause
    exit /b
)

:: Write active session credential for client and translator
echo %username% > "%~dp0current_user.dat"
echo [OK] Login successful!
timeout /t 1 >nul
exit /b 0
