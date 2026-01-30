# Mattermost Push Proxy - Cloudron App

Cloudron package for Mattermost Push Notification Service (MPNS).

## Overview

This Cloudron app packages the Mattermost Push Proxy service, which is required for custom Mattermost mobile applications to receive push notifications.

## Deployment

### 1. Build and Deploy to Docker Hub

```bash
.\deploy.bat 6.4.6
```

### 2. Install on Cloudron

1. Go to your Cloudron dashboard
2. Click "Install App" → "Custom App"
3. Use Docker Hub image: `yourusername/mattermost-push-proxy-cloudron`
4. Install the app

### 3. Configure Push Certificates

After installation, you need to upload push certificates:

#### For iOS (Choose one method):

**Method A: Apple Push Certificate**
```bash
# Upload to /app/data/certs/apple_push_cert.pem
```

**Method B: Apple Auth Key (Recommended)**
```bash
# Upload to /app/data/certs/apple_auth_key.p8
```

#### For Android:
```bash
# Upload Firebase service account JSON to:
# /app/data/certs/firebase_service_account.json
```

### 4. Edit Configuration

Edit `/app/data/config/mattermost-push-proxy.json`:

```json
{
  "ApplePushSettings": [
    {
      "Type": "apple_rn",
      "ApplePushTopic": "com.yourcompany.mattermost",
      "AppleAuthKeyID": "YOUR_KEY_ID",
      "AppleTeamID": "YOUR_TEAM_ID"
    }
  ]
}
```

Replace:
- `com.yourcompany.mattermost` with your iOS app bundle ID
- `YOUR_KEY_ID` with your Apple Auth Key ID (if using Auth Key method)
- `YOUR_TEAM_ID` with your Apple Team ID

### 5. Restart the App

Restart the Cloudron app to apply changes.

### 6. Configure Mattermost Server

In your Mattermost server (System Console):

1. Go to **Environment > Push Notification Server**
2. Select **"Manually enter Push Notification Service location"**
3. Enter: `https://your-push-proxy-domain.com`
4. Save

## Getting Push Certificates

### iOS - Apple Auth Key (Recommended)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Create a new key with "Apple Push Notifications service (APNs)" enabled
3. Download the `.p8` file
4. Note the Key ID and Team ID

### Android - Firebase Service Account

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Download the JSON file

## File Structure

```
/app/data/
├── certs/
│   ├── apple_auth_key.p8           # iOS Auth Key (method B)
│   ├── apple_push_cert.pem         # iOS Certificate (method A)
│   └── firebase_service_account.json  # Android
└── config/
    └── mattermost-push-proxy.json  # Main config
```

## Health Check

The service provides a health check endpoint at:
```
https://your-push-proxy-domain.com/api/v1/health
```

## Troubleshooting

### App won't start

- Check that certificates exist in `/app/data/certs/`
- Verify config file syntax in `/app/data/config/mattermost-push-proxy.json`
- Check logs in Cloudron dashboard

### Notifications not received

- Verify Mattermost server config points to correct push proxy URL
- Check that bundle IDs match between:
  - iOS app configuration
  - Push proxy `ApplePushTopic`
  - Apple Push certificate/key
- Verify Firebase service account has correct permissions

## Links

- [Mattermost Push Proxy](https://github.com/mattermost/mattermost-push-proxy)
- [Push Notifications Documentation](https://developers.mattermost.com/contribute/mobile/push-notifications/service/)
- [Cloudron Documentation](https://docs.cloudron.io/)

## Version

- **Cloudron Package**: 0.1.0
- **Upstream Version**: 6.4.6
