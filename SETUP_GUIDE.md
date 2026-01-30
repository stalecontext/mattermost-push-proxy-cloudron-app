# Mattermost Push Proxy Setup Guide

Complete guide to setting up your own push proxy service for your custom Mattermost mobile app.

## Prerequisites

Before starting, you need:

1. **Apple Developer Account** ($99/year)
   - For iOS push notifications
   - Need Team ID and ability to create Auth Keys

2. **Firebase Project** (Free)
   - For Android push notifications
   - Need to create a service account

3. **Cloudron Instance**
   - Running and accessible
   - Docker Hub account configured

4. **Custom Mattermost Mobile App**
   - Built and signed with your own bundle IDs
   - iOS: `com.yourcompany.mattermost` (example)
   - Android: `com.yourcompany.mattermost` (example)

## Quick Start

### Phase 0: Configure Environment

#### 1. Create Your Configuration File

```bash
cd /path/to/mattermost-push-proxy-cloudron-app

# Create .env from template
.\setup-env.bat

# Or manually:
copy .env.example .env
notepad .env
```

#### 2. Fill in Your Values

Edit `.env` and provide:

```bash
# Cloudron Settings
CLOUDRON_DOMAIN=my.yourdomain.com
PUSH_PROXY_DOMAIN=push.yourdomain.com
MATTERMOST_DOMAIN=chat.yourdomain.com

# Docker Hub
DOCKER_USERNAME=yourusername

# iOS (get these from Apple Developer portal)
IOS_BUNDLE_ID=com.yourcompany.mattermost
APPLE_TEAM_ID=ABC1234DEF
APPLE_AUTH_KEY_ID=XYZ9876543
APPLE_AUTH_KEY_FILE=AuthKey_XYZ9876543.p8

# Android (get these from Firebase)
ANDROID_PACKAGE_NAME=com.yourcompany.mattermost
FIREBASE_SERVICE_ACCOUNT_FILE=firebase-service-account.json

# Version
PUSH_PROXY_VERSION=6.4.6
```

**Where to find these values:**
- iOS values: `mattermost-mobile/fastlane/.env.ios.testflight` (if using TestFlight)
- Android package: `mattermost-mobile/android/app/build.gradle` (look for `applicationId`)
- Apple Team ID: https://developer.apple.com/account (top right corner)
- Apple Auth Key ID: From the `.p8` filename

### Phase 1: Get Push Certificates

#### iOS - Apple Auth Key Method (Recommended)

1. **Create Apple Auth Key**
   - Go to: https://developer.apple.com/account/resources/authkeys/list
   - Click "+" to create a new key
   - Name it: "Mattermost Push Notifications"
   - Enable: **"Apple Push Notifications service (APNs)"** ✅
   - Click "Continue" → "Register" → "Download"
   - **Save the `.p8` file securely** (you can only download once!)

2. **Important Settings:**
   - **Environment**: Auth Keys work for both Development and Production automatically
   - **Key Restriction**: Not applicable - Auth Keys work for all apps under your Team ID
   - **Services**: Only enable "Apple Push Notifications service (APNs)"

3. **Note these values** (you'll need them for `.env`):
   ```
   File: AuthKey_XYZ9876543.p8
   Key ID: XYZ9876543 (from filename)
   Team ID: ABC1234DEF (from Apple Developer portal, top right)
   ```

4. **Save the `.p8` file** to your push proxy directory:
   ```bash
   # Copy to the push proxy directory
   copy AuthKey_XYZ9876543.p8 G:\path\to\mattermost-push-proxy-cloudron-app\
   ```

#### Android - Firebase Service Account

1. **Create/Select Firebase Project**
   - Go to: https://console.firebase.google.com/
   - Create new project or select existing one
   - Name it: "Mattermost Mobile"

2. **Add Android App** (if not already added)
   - Click "Add app" → Android icon
   - Package name: Your Android bundle ID (e.g., `com.yourcompany.mattermost`)
   - Download `google-services.json` (needed for mobile app build)

3. **Generate Service Account Key**
   - In Firebase Console, click gear icon → "Project settings"
   - Go to "Service accounts" tab
   - Click "Generate new private key"
   - Confirm and download JSON file
   - **Save securely** (contains private credentials)

4. **Save the JSON file** to your push proxy directory:
   ```bash
   # Copy to the push proxy directory
   copy firebase-service-account.json G:\path\to\mattermost-push-proxy-cloudron-app\
   ```

### Phase 2: Deploy Push Proxy to Cloudron

#### One-Step Installation

```bash
cd /path/to/mattermost-push-proxy-cloudron-app

# Login to Docker and Cloudron (first time only)
docker login
cloudron login

# Install to Cloudron (builds, pushes, and installs automatically)
.\install-cloudron.bat
```

**What this does:**
1. Reads your `.env` configuration
2. Builds the Docker image with your settings
3. Pushes to Docker Hub
4. Installs the app to your Cloudron instance
5. Provides next steps for uploading certificates

**Expected time:** ~10-15 minutes

#### Upload Certificates After Installation

After the install script completes, upload your certificates:

```bash
# Upload iOS Auth Key
cloudron push --app push.yourdomain.com AuthKey_XYZ9876543.p8 /app/data/certs/apple_auth_key.p8

# Upload Android Service Account
cloudron push --app push.yourdomain.com firebase-service-account.json /app/data/certs/firebase_service_account.json
```

#### Configure Push Proxy

**Option A: Via Cloudron Web Terminal**

1. Open app in Cloudron dashboard
2. Click "Terminal" tab
3. Edit config:
   ```bash
   vi /app/data/config/mattermost-push-proxy.json
   ```

**Option B: Via Cloudron CLI**

```bash
# Download config
cloudron pull --app push.yourdomain.com /app/data/config/mattermost-push-proxy.json ./push-proxy-config.json

# Edit locally
notepad push-proxy-config.json

# Upload back
cloudron push --app push.yourdomain.com ./push-proxy-config.json /app/data/config/mattermost-push-proxy.json
```

**Edit these values:**
```json
{
  "ApplePushSettings": [
    {
      "Type": "apple_rn",
      "ApplePushUseDevelopment": false,
      "ApplePushTopic": "com.yourcompany.mattermost",
      "AppleAuthKeyFile": "/app/data/certs/apple_auth_key.p8",
      "AppleAuthKeyID": "XYZ9876543",
      "AppleTeamID": "ABC1234DEF"
    }
  ],
  "AndroidPushSettings": [
    {
      "Type": "android_rn",
      "ServiceFileLocation": "/app/data/certs/firebase_service_account.json"
    }
  ]
}
```

**Use your values from `.env`:**
- `ApplePushTopic` → `IOS_BUNDLE_ID`
- `AppleAuthKeyID` → `APPLE_AUTH_KEY_ID`
- `AppleTeamID` → `APPLE_TEAM_ID`

#### Restart and Verify

1. **Restart the app** in Cloudron dashboard

2. **Verify health check:**
   ```bash
   curl https://push.yourdomain.com/api/v1/health
   # Should return: {"status":"ok"}
   ```

### Phase 3: Configure Mattermost Server

#### Update Mattermost Push Notification Server

**Option A: Via System Console (Web UI)**

1. Login as System Admin
2. Go to **System Console** (top left menu)
3. Navigate to **Environment > Push Notification Server**
4. Select **"Manually enter Push Notification Service location"**
5. Enter: `https://push.yourdomain.com`
6. Click "Save"

**Option B: Via Config File**

If you manage Mattermost via config files:

```json
{
  "EmailSettings": {
    "SendPushNotifications": true,
    "PushNotificationServer": "https://push.yourdomain.com",
    "PushNotificationContents": "generic"
  }
}
```

### Phase 4: Configure Mobile App

#### iOS App Configuration

In your `mattermost-mobile` repository:

1. **Verify bundle ID** matches your `.env`:
   - Check `fastlane/.env.ios.testflight`
   - `MAIN_APP_IDENTIFIER` should match `IOS_BUNDLE_ID` in push proxy `.env`

2. **Verify Push Notifications capability** is enabled:
   - Xcode → Project → Signing & Capabilities
   - Should have "Push Notifications" capability

3. **Build and deploy** via TestFlight:
   ```bash
   cd /path/to/mattermost-mobile
   ./scripts/deploy-testflight.sh
   ```

#### Android App Configuration

In your `mattermost-mobile` repository:

1. **Add Firebase config:**
   - Copy `google-services.json` to `android/app/google-services.json`

2. **Verify package name** matches:
   - Check `android/app/build.gradle`
   - `applicationId` should match `ANDROID_PACKAGE_NAME` in push proxy `.env`

3. **Build APK:**
   ```bash
   cd /path/to/mattermost-mobile
   npm run build:android
   ```

### Phase 5: Test Push Notifications

#### 1. Install Mobile App

- **iOS**: Install via TestFlight
- **Android**: Install APK on device

#### 2. Login to Mattermost

- Open app
- Enter server URL (your Mattermost server)
- Login with your credentials

#### 3. Test Notifications

1. **Put app in background** (press home button)
2. **Send yourself a message** from another device/browser
3. **Check for push notification** on mobile device

#### 4. Troubleshooting

**No notifications received?**

1. **Check push proxy logs:**
   ```bash
   cloudron logs --app push.yourdomain.com
   ```

2. **Verify certificates are uploaded:**
   ```bash
   cloudron exec --app push.yourdomain.com -- ls -la /app/data/certs/
   ```

3. **Verify push proxy config:**
   ```bash
   cloudron exec --app push.yourdomain.com -- cat /app/data/config/mattermost-push-proxy.json
   ```

4. **Check bundle IDs match:**
   - iOS app bundle ID (in Xcode or fastlane config)
   - `ApplePushTopic` in push proxy config
   - Apple Developer portal certificate

5. **Verify Mattermost server config:**
   - System Console → Push Notification Server
   - Should point to: `https://push.yourdomain.com`

6. **Common issues:**
   - Bundle ID mismatch
   - Wrong Team ID or Auth Key ID
   - Certificate file permissions
   - Firebase project not configured correctly
   - Push proxy not accessible (check firewall/DNS)

## Updating the Push Proxy

### Update to New Upstream Version

When a new version of mattermost-push-proxy is released:

```bash
cd /path/to/mattermost-push-proxy-cloudron-app

# Update version in .env
notepad .env
# Change: PUSH_PROXY_VERSION=6.5.0

# Build and push new version
.\deploy.bat

# Update in Cloudron dashboard (click UPDATE button)
# OR use direct update:
.\update-cloudron.bat
```

### Update Cloudron Package Version

When you make changes to the Cloudron package (Dockerfile, start.sh, etc.):

```bash
# Edit CloudronManifest.json
notepad CloudronManifest.json
# Increment version: "version": "0.2.0"

# Rebuild and deploy
.\deploy.bat

# Update in Cloudron dashboard
```

## Security Notes

### Protect Your Credentials

**NEVER commit these files to git:**
- `.env` - Your configuration (already gitignored)
- `*.p8` files - Apple Auth Keys
- `*firebase*.json` - Firebase service accounts
- `install-cloudron.bat` - Contains your domain
- `update-cloudron.bat` - Contains your domain

**These are safe to commit:**
- `.env.example` - Template with placeholders
- All documentation files
- `deploy.bat`, `configure-cloudron.bat` - Read from .env

### File Permissions

The push proxy runs as user `cloudron:cloudron`. All files in `/app/data/` are automatically chowned on startup.

### HTTPS Only

Both Mattermost server and push proxy should use HTTPS. Cloudron handles this automatically.

## Maintenance

### Renew/Update Certificates

**Apple Auth Keys:**
- Never expire (unless revoked)
- Can be regenerated if lost
- Need to update push proxy config if regenerated

**Firebase Service Accounts:**
- Never expire (unless deleted)
- Can generate multiple keys for rotation
- Update push proxy config and restart after rotation

### Backup Important Files

Backup these critical files:

```bash
# Local backups (do this first!)
/app/data/certs/apple_auth_key.p8
/app/data/certs/firebase_service_account.json
/app/data/config/mattermost-push-proxy.json

# Download via Cloudron CLI
cloudron pull --app push.yourdomain.com /app/data/certs/ ./backup/certs/
cloudron pull --app push.yourdomain.com /app/data/config/ ./backup/config/
```

## Reference

### File Locations

**On your machine:**
```
mattermost-push-proxy-cloudron-app/
├── .env                              # Your configuration (NOT committed)
├── .env.example                      # Template (committed)
├── AuthKey_XYZ9876543.p8             # Apple Auth Key (NOT committed)
├── firebase-service-account.json     # Firebase credentials (NOT committed)
├── install-cloudron.bat              # First-time install (NOT committed)
├── update-cloudron.bat               # Direct update (NOT committed)
├── deploy.bat                        # Build and push (committed)
└── ... (other files)
```

**On Cloudron server:**
```
/app/code/                            # Push proxy binary
├── bin/mattermost-push-proxy
└── config/

/app/data/                            # Persistent data
├── certs/
│   ├── apple_auth_key.p8
│   └── firebase_service_account.json
└── config/
    └── mattermost-push-proxy.json
```

### Quick Reference Commands

```bash
# Setup
.\setup-env.bat                      # Create .env from template
.\install-cloudron.bat               # First-time install

# Update
.\deploy.bat                         # Build and push to Docker Hub
.\update-cloudron.bat                # Direct update to Cloudron

# Cloudron operations
cloudron logs --app push.yourdomain.com
cloudron exec --app push.yourdomain.com -- ls /app/data/certs/
cloudron push --app push.yourdomain.com file.p8 /app/data/certs/
cloudron pull --app push.yourdomain.com /app/data/certs/ ./backup/

# Health check
curl https://push.yourdomain.com/api/v1/health
```

### Links

- **Apple Developer**: https://developer.apple.com/account/
- **Firebase Console**: https://console.firebase.google.com/
- **Mattermost Push Notifications Docs**: https://developers.mattermost.com/contribute/mobile/push-notifications/service/
- **Cloudron Docs**: https://docs.cloudron.io/

---

**Need help?** Check the [Mattermost Push Notifications documentation](https://developers.mattermost.com/contribute/mobile/push-notifications/service/)
