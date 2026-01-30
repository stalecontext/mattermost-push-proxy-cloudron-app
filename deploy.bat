@echo off
setlocal enabledelayedexpansion

:: Mattermost Push Proxy Cloudron App Deploy Script
:: Usage: deploy.bat <push-proxy-version>
:: Example: deploy.bat 6.4.6

if "%~1"=="" (
    echo Usage: deploy.bat ^<push-proxy-version^>
    echo Example: deploy.bat 6.4.6
    exit /b 1
)

set PUSH_PROXY_VERSION=%~1

:: Remove v prefix if present
set PUSH_PROXY_VERSION=%PUSH_PROXY_VERSION:v=%

echo.
echo ================================================================================
echo Mattermost Push Proxy - Cloudron Deployment
echo ================================================================================
echo Push Proxy Version: %PUSH_PROXY_VERSION%
echo ================================================================================
echo.

:: Check if cloudron CLI is installed
echo Checking for Cloudron CLI...
where cloudron >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Cloudron CLI is not installed or not in PATH
    echo.
    echo Install it with: npm install -g cloudron
    echo Or see: https://docs.cloudron.io/packaging/cli/
    echo.
    exit /b 1
)

echo Cloudron CLI found: OK
echo.

:: Check if docker is logged in
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Docker is not running or not logged in
    echo.
    echo Please run: docker login
    echo.
    exit /b 1
)

echo Docker login: OK
echo.

:: Check if cloudron build is configured
if not exist "%USERPROFILE%\.cloudron.json" (
    echo.
    echo ERROR: Cloudron build not configured yet
    echo.
    echo Please run configure-cloudron.bat first to set up Docker Hub integration.
    echo.
    exit /b 1
)

echo Cloudron build configured: OK
echo.

echo ================================================================================
echo Fixing Shell Script Line Endings
echo ================================================================================
echo.
echo Ensuring start.sh has Unix (LF) line endings...
powershell -Command "$content = Get-Content 'start.sh' -Raw; $content = $content -replace \"`r`n\", \"`n\"; $content = $content -replace \"`r\", \"`n\"; [System.IO.File]::WriteAllText('start.sh', $content)"
if errorlevel 1 (
    echo Error: Failed to fix line endings
    exit /b 1
)
echo Line endings fixed: OK
echo.

echo ================================================================================
echo Updating Dockerfile
echo ================================================================================
echo.

:: Backup Dockerfile
copy Dockerfile Dockerfile.bak >nul

:: Update Dockerfile PUSH_PROXY_VERSION
echo Updating PUSH_PROXY_VERSION to %PUSH_PROXY_VERSION%...
powershell -Command "(Get-Content Dockerfile) -replace 'ARG PUSH_PROXY_VERSION=.*', 'ARG PUSH_PROXY_VERSION=%PUSH_PROXY_VERSION%' | Set-Content Dockerfile"
if errorlevel 1 (
    echo Error: Failed to update Dockerfile
    move /y Dockerfile.bak Dockerfile >nul
    exit /b 1
)

:: Clean up backup
del Dockerfile.bak

:: Show changes
echo.
echo Changes made to Dockerfile:
git diff Dockerfile
echo.

echo ================================================================================
echo Building and Pushing to Docker Hub
echo ================================================================================
echo.
echo This will:
echo 1. Build the Docker image locally
echo 2. Push it to your Docker Hub repository
echo 3. Cloudron will detect the update and show UPDATE button
echo.

:: Get Docker repository from cloudron config
for /f "tokens=*" %%a in ('powershell -Command "$config = Get-Content '%USERPROFILE%\.cloudron.json' | ConvertFrom-Json; $config.docker.repository"') do set DOCKER_REPO=%%a

if "%DOCKER_REPO%"=="" (
    echo ERROR: Could not read Docker repository from cloudron config
    exit /b 1
)

echo Docker Repository: %DOCKER_REPO%
echo.

:: Build and push
echo Building Docker image with --no-cache to ensure fresh build...
docker build --no-cache -t %DOCKER_REPO%:temp-build .
if errorlevel 1 (
    echo.
    echo ERROR: Docker build failed
    echo.
    echo Restoring original Dockerfile...
    git checkout Dockerfile
    exit /b 1
)

echo.
echo Pushing to Docker Hub...
docker push %DOCKER_REPO%:temp-build
if errorlevel 1 (
    echo.
    echo ERROR: Docker push failed
    echo.
    git checkout Dockerfile
    exit /b 1
)

:: Extract version from CloudronManifest.json
echo.
echo ================================================================================
echo Tagging Image with CloudronManifest.json Version
echo ================================================================================
echo.
for /f "tokens=2 delims=:" %%a in ('findstr /R "\"version\":" CloudronManifest.json') do (
    set VERSION_LINE=%%a
)
:: Remove quotes, commas, and spaces
set CLOUDRON_VERSION=%VERSION_LINE:"=%
set CLOUDRON_VERSION=%CLOUDRON_VERSION:,=%
set CLOUDRON_VERSION=%CLOUDRON_VERSION: =%

echo CloudronManifest.json version: %CLOUDRON_VERSION%

:: Tag with version
echo Tagging temp-build as %CLOUDRON_VERSION%...
docker tag %DOCKER_REPO%:temp-build %DOCKER_REPO%:%CLOUDRON_VERSION%
if errorlevel 1 (
    echo Warning: Failed to tag image with version %CLOUDRON_VERSION%
    goto :skip_version_push
)

:: Push version tag
echo Pushing %CLOUDRON_VERSION% to Docker Hub...
docker push %DOCKER_REPO%:%CLOUDRON_VERSION%
if errorlevel 1 (
    echo Warning: Failed to push version tag %CLOUDRON_VERSION%
    goto :skip_version_push
)

echo Successfully pushed version tag %CLOUDRON_VERSION%!

:: Clean up temp tag
docker rmi %DOCKER_REPO%:temp-build >nul 2>&1

:skip_version_push

echo.
echo ================================================================================
echo SUCCESS! Build Pushed to Docker Hub
echo ================================================================================
echo.
echo The new version has been pushed to Docker Hub.
echo.
echo Next steps:
echo 1. Go to your Cloudron dashboard
echo 2. Wait 1-2 minutes for Cloudron to detect the update
echo 3. Click the UPDATE button when it appears
echo 4. Monitor logs during update
echo.
echo To commit Dockerfile changes:
echo   git add Dockerfile
echo   git commit -m "Update to %PUSH_PROXY_VERSION%"
echo   git push
echo.
echo To revert Dockerfile changes:
echo   git checkout Dockerfile
echo.
echo ================================================================================

endlocal
