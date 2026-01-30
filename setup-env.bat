@echo off
:: Setup .env file from template
:: This is a helper script to create your .env configuration file

echo.
echo ================================================================================
echo Setup Push Proxy Environment Configuration
echo ================================================================================
echo.

if exist .env (
    echo WARNING: .env file already exists!
    echo.
    set /p OVERWRITE="Do you want to overwrite it? (y/n): "
    if /i not "%OVERWRITE%"=="y" (
        echo Setup cancelled. Your existing .env file was not modified.
        exit /b 0
    )
)

echo Creating .env from .env.example...
copy .env.example .env >nul

if errorlevel 1 (
    echo ERROR: Failed to create .env file
    exit /b 1
)

echo.
echo SUCCESS! .env file created.
echo.
echo ================================================================================
echo Next Steps:
echo ================================================================================
echo.
echo 1. Open .env in your editor:
echo    notepad .env
echo.
echo 2. Fill in your configuration values:
echo    - CLOUDRON_DOMAIN (e.g., my.sourcemod.xyz)
echo    - PUSH_PROXY_DOMAIN (e.g., push.sourcemod.xyz)
echo    - DOCKER_USERNAME (e.g., stalecontext)
echo    - IOS_BUNDLE_ID (your iOS app bundle ID)
echo    - APPLE_TEAM_ID (from Apple Developer portal)
echo    - APPLE_AUTH_KEY_ID (from .p8 filename)
echo    - APPLE_AUTH_KEY_FILE (path to .p8 file)
echo    - ANDROID_PACKAGE_NAME (your Android package)
echo    - FIREBASE_SERVICE_ACCOUNT_FILE (path to Firebase JSON)
echo.
echo 3. Save the file
echo.
echo 4. Run the install script:
echo    .\install-cloudron.bat
echo.
echo ================================================================================
echo.
echo Opening .env in notepad...
notepad .env

exit /b 0
