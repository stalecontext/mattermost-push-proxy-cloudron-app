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

## Step-by-Step Setup

### Phase 1: Get Push Certificates

#### iOS - Apple Auth Key Method (Recommended)

1. **Create Apple Auth Key**
   - Go to: https://developer.apple.com/account/resources/authkeys/list
   - Click "+" to create a new key
   - Name it: "Mattermost Push Notifications"
   - Enable: "Apple Push Notifications service (APNs)"
   - Click "Continue" → "Register" → "Download"
   - **Save the `.p8` file securely** (you can only download once!)
   - **Note the Key ID** (e.g., `AB12CD34EF`)
   - **Note your Team ID** (found in top right of Apple Developer portal, e.g., `XYZ1234567`)

2. **Save the information**
   ```
   File: AuthKey_AB12CD34EF.p8
   Key ID: AB12CD34EF
   Team ID: XYZ1234567
   ```

#### Android - Firebase Service Account

1. **Create Firebase Project**
   - Go to: https://console.firebase.google.com/
   - Click "Add project" or select existing project
   - Name it: "Mattermost Mobile"

2. **Add Android App** (if not already added)
   - Click "Add app" → Android icon
   - Package name: Your Android bundle ID (e.g., `com.yourcompany.mattermost`)
   - Download `google-services.json` (needed for mobile app)

3. **Generate Service Account Key**
   - In Firebase Console, click gear icon → "Project settings"
   - Go to "Service accounts" tab
   - Click "Generate new private key"
   - Confirm and download JSON file
   - **Save securely** (contains private credentials)

### Phase 2: Deploy Push Proxy to Cloudron

#### 1. Build and Push Docker Image

```bash
cd /path/to/mattermost-push-proxy-cloudron-app

# Login to Docker Hub
docker login

# Login to Cloudron
cloudron login

# Deploy (builds and pushes to Docker Hub)
.\deploy.bat 6.4.6
```

This will:
- Build the Docker image
- Push to Docker Hub as `yourusername/mattermost-push-proxy-cloudron`
- Take ~5-10 minutes

#### 2. Install on Cloudron

1. Go to Cloudron dashboard: https://my.yourdomain.com
2. Click "App Store"
3. Search for "Mattermost Push Proxy" (if published)
   - OR click "Install Unverified App"
   - Docker image: `yourusername/mattermost-push-proxy-cloudron:latest`
4. Choose subdomain: e.g., `push` → `push.yourdomain.com`
5. Click "Install"
6. Wait for installation (~2-3 minutes)

#### 3. Upload Certificates via Cloudron CLI

```bash
# Set your app domain
set APP_DOMAIN=push.yourdomain.com

# Upload iOS Auth Key
cloudron push --server my.yourdomain.com --app %APP_DOMAIN% AuthKey_AB12CD34EF.p8 /app/data/certs/apple_auth_key.p8

# Upload Android Service Account
cloudron push --server my.yourdomain.com --app %APP_DOMAIN% firebase-service-account.json /app/data/certs/firebase_service_account.json
```

#### 4. Configure Push Proxy

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
cloudron pull --server my.yourdomain.com --app push.yourdomain.com /app/data/config/mattermost-push-proxy.json ./push-proxy-config.json

# Edit locally
notepad push-proxy-config.json

# Upload back
cloudron push --server my.yourdomain.com --app push.yourdomain.com ./push-proxy-config.json /app/data/config/mattermost-push-proxy.json
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
      "AppleAuthKeyID": "AB12CD34EF",
      "AppleTeamID": "XYZ1234567"
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

Replace:
- `com.yourcompany.mattermost` → Your iOS bundle ID
- `AB12CD34EF` → Your Apple Auth Key ID
- `XYZ1234567` → Your Apple Team ID

#### 5. Restart the App

In Cloudron dashboard:
1. Click on the push proxy app
2. Click "Restart"
3. Wait for it to come back online (~30 seconds)

#### 6. Verify Health Check

Test the push proxy is working:
```bash
curl https://push.yourdomain.com/api/v1/health
```

Should return:
```json
{"status":"ok"}
```

### Phase 3: Configure Mattermost Server

#### Update Mattermost Config

**Option A: Via System Console (Web UI)**

1. Login as System Admin to https://chat.yourdomain.com
2. Go to **System Console** (top left menu)
3. Navigate to **Environment > Push Notification Server**
4. Select **"Manually enter Push Notification Service location"**
5. Enter: `https://push.yourdomain.com`
6. Click "Save"

**Option B: Via Config File**

Edit your Mattermost Cloudron app config:

```bash
cd /path/to/mattermost-cloudron-app

# Update config.json.template
# Line 219: Change PushNotificationServer value
```

```json
{
  "EmailSettings": {
    "SendPushNotifications": true,
    "PushNotificationServer": "https://push.yourdomain.com",
    "PushNotificationContents": "generic"
  }
}
```

Rebuild and deploy Mattermost:
```bash
.\build.bat 11.3.0-custom.5 "Configure custom push proxy"
# Wait for GitHub Actions build...

cd /path/to/mattermost-cloudron-app
.\deploy.bat 11.3.0-custom.5
```

### Phase 4: Configure Mobile App

#### iOS App Configuration

In your `mattermost-mobile` repository:

1. **Update bundle ID** (if not already done)
   - `ios/Mattermost.xcodeproj` → Bundle Identifier: `com.yourcompany.mattermost`

2. **Add Push Notifications capability**
   - Xcode → Project → Signing & Capabilities
   - Click "+ Capability"
   - Add "Push Notifications"

3. **Update push notification handling**
   - The app should already be configured for APNS
   - Verify `ios/Mattermost/AppDelegate.mm` has push notification code

4. **Build and sign with your Team ID**

#### Android App Configuration

In your `mattermost-mobile` repository:

1. **Add Firebase config**
   - Copy `google-services.json` to `android/app/google-services.json`

2. **Update bundle ID** (if not already done)
   - Edit `android/app/build.gradle`:
     ```gradle
     defaultConfig {
         applicationId "com.yourcompany.mattermost"
     }
     ```

3. **Build APK**
   ```bash
   cd /path/to/mattermost-mobile
   npm run build:android
   ```

### Phase 5: Test Push Notifications

#### 1. Install Mobile App

- **iOS**: Install via TestFlight or direct installation
- **Android**: Install APK on device

#### 2. Login to Mattermost

- Open app
- Enter server URL: `https://chat.yourdomain.com`
- Login with your credentials

#### 3. Test Notifications

1. **Put app in background** (press home button)
2. **Send yourself a message** from another device/browser
3. **Check for push notification** on mobile device

#### 4. Troubleshooting

**No notifications received?**

1. **Check push proxy logs**
   ```bash
   cloudron logs --server my.yourdomain.com --app push.yourdomain.com
   ```

2. **Verify server config**
   ```bash
   # In Mattermost server
   curl http://localhost:8065/api/v4/config/client
   # Look for "SendPushNotifications": true
   ```

3. **Check mobile app registration**
   - App should register device token on login
   - Check for errors in mobile app logs

4. **Common issues**
   - Bundle ID mismatch (app vs push proxy config)
   - Wrong Team ID or Auth Key ID
   - Certificate file permissions
   - Firebase project not configured correctly

## Security Notes

### Protect Your Credentials

- **NEVER commit** `.p8` files or Firebase JSON to git
- Add to `.gitignore`:
  ```
  *.p8
  *firebase*.json
  google-services.json
  ```

### File Permissions

The push proxy runs as user `cloudron:cloudron`. All files in `/app/data/` are automatically chowned.

### HTTPS Only

Both Mattermost server and push proxy should use HTTPS. Cloudron handles this automatically.

## Maintenance

### Update Push Proxy

When a new version is released:

```bash
cd /path/to/mattermost-push-proxy-cloudron-app

# Update version
.\deploy.bat 6.5.0

# In Cloudron dashboard, click "Update" on the push proxy app
```

### Renew Certificates

- **Apple Auth Keys**: Never expire (unless revoked)
- **Firebase Service Accounts**: Never expire (unless deleted)

### Backup

Backup these critical files:
```
/app/data/certs/apple_auth_key.p8
/app/data/certs/firebase_service_account.json
/app/data/config/mattermost-push-proxy.json
```

Download via Cloudron CLI:
```bash
cloudron pull --server my.yourdomain.com --app push.yourdomain.com /app/data/certs/ ./backup/
cloudron pull --server my.yourdomain.com --app push.yourdomain.com /app/data/config/ ./backup/
```

## Reference

- **Push Proxy Repo**: `/path/to/mattermost-push-proxy`
- **Cloudron Package**: `/path/to/mattermost-push-proxy-cloudron-app`
- **Mobile App**: `/path/to/mattermost-mobile`
- **Mattermost Server**: `/path/to/mattermost`

- **Apple Developer**: https://developer.apple.com/account/
- **Firebase Console**: https://console.firebase.google.com/
- **Cloudron Dashboard**: https://my.yourdomain.com
- **Push Proxy**: https://push.yourdomain.com (after setup)
- **Mattermost Server**: https://chat.yourdomain.com

## Quick Reference

| Item | Value |
|------|-------|
| **iOS Bundle ID** | `com.yourcompany.mattermost` |
| **Android Package** | `com.yourcompany.mattermost` |
| **Apple Team ID** | Found in Apple Developer portal |
| **Apple Auth Key ID** | From downloaded `.p8` filename |
| **Push Proxy URL** | `https://push.yourdomain.com` |
| **Mattermost Server** | `https://chat.yourdomain.com` |
| **Health Check** | `https://push.yourdomain.com/api/v1/health` |

---

**Need help?** Check the [Mattermost Push Notifications documentation](https://developers.mattermost.com/contribute/mobile/push-notifications/service/)
