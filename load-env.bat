@echo off
:: Load environment variables from .env file
:: This script should be called from other scripts using: call load-env.bat

if not exist .env (
    echo.
    echo ERROR: .env file not found!
    echo.
    echo Please create your .env file first:
    echo 1. Run: .\setup-env.bat
    echo 2. Edit .env with your configuration
    echo 3. Try again
    echo.
    exit /b 1
)

:: Read .env file and set variables
for /f "usebackq tokens=1,* delims==" %%a in (.env) do (
    set "line=%%a"
    set "value=%%b"

    :: Skip empty lines and comments
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            :: Expand variables in value (e.g., ${DOCKER_USERNAME})
            set "value=!value:${DOCKER_USERNAME}=%DOCKER_USERNAME%!"

            :: Set the variable
            set "%%a=!value!"
        )
    )
)

:: Verify required variables are set
set MISSING=0

if "%CLOUDRON_DOMAIN%"=="" (
    echo ERROR: CLOUDRON_DOMAIN not set in .env
    set MISSING=1
)

if "%PUSH_PROXY_DOMAIN%"=="" (
    echo ERROR: PUSH_PROXY_DOMAIN not set in .env
    set MISSING=1
)

if "%DOCKER_USERNAME%"=="" (
    echo ERROR: DOCKER_USERNAME not set in .env
    set MISSING=1
)

if "%DOCKER_REPO%"=="" (
    echo ERROR: DOCKER_REPO not set in .env
    set MISSING=1
)

if %MISSING%==1 (
    echo.
    echo Please edit your .env file and fill in the required values.
    exit /b 1
)

:: Success - variables loaded
exit /b 0
