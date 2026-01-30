# Next Steps - Push Proxy Setup

Quick checklist for getting your push proxy running.

## Current Status

✅ Cloudron package created
✅ Git repository initialized
⬜ Push to GitHub
⬜ Get iOS certificates
⬜ Get Android certificates
⬜ Deploy to Cloudron
⬜ Configure Mattermost server
⬜ Test notifications

## Immediate Next Steps

### 1. Push to GitHub

Create a GitHub repository and push the code:

```bash
# Create repo on GitHub: mattermost-push-proxy-cloudron-app
# Then:
cd /path/to/mattermost-push-proxy-cloudron-app
git remote add origin https://github.com/yourusername/mattermost-push-proxy-cloudron-app.git
git branch -M master
git push -u origin master
```

### 2. Get iOS Certificates

**Apple Auth Key (Recommended)**

1. Go to: https://developer.apple.com/account/resources/authkeys/list
2. Create new key with APNs enabled
3. Download `.p8` file
4. Save Key ID and Team ID

**What you need:**
- [ ] `AuthKey_XXXXXXXXXX.p8` file
- [ ] Key ID (e.g., `AB12CD34EF`)
- [ ] Team ID (e.g., `XYZ1234567`)
- [ ] iOS Bundle ID from your mobile app (e.g., `com.yourcompany.mattermost`)

### 3. Get Android Certificates

**Firebase Service Account**

1. Go to: https://console.firebase.google.com/
2. Create or select project
3. Add Android app with your bundle ID
4. Download `google-services.json` (for mobile app)
5. Go to Project Settings → Service Accounts
6. Generate new private key
7. Download JSON file

**What you need:**
- [ ] Firebase service account JSON file
- [ ] `google-services.json` for mobile app
- [ ] Android package name (e.g., `com.yourcompany.mattermost`)

### 4. Configure Mobile App

Before deploying push proxy, configure your mobile app:

**iOS** (`G:\Modding\_Github\mattermost-mobile`):
- [ ] Set bundle ID in Xcode
- [ ] Enable Push Notifications capability
- [ ] Build and sign with your Team ID

**Android** (`G:\Modding\_Github\mattermost-mobile`):
- [ ] Copy `google-services.json` to `android/app/`
- [ ] Set package name in `android/app/build.gradle`
- [ ] Build APK

### 5. Deploy Push Proxy

```bash
cd G:\Modding\_Github\mattermost-push-proxy-cloudron-app

# Build and push to Docker Hub
.\deploy.bat 6.4.6
```

### 6. Install on Cloudron

1. Go to Cloudron dashboard
2. Install custom app: `yourusername/mattermost-push-proxy-cloudron`
3. Choose subdomain: `push.yourdomain.com`

### 7. Upload Certificates

```bash
# Upload iOS Auth Key
cloudron push --server my.yourdomain.com --app push.yourdomain.com AuthKey_XXXXXXXXXX.p8 /app/data/certs/apple_auth_key.p8

# Upload Android Service Account
cloudron push --server my.yourdomain.com --app push.yourdomain.com firebase-adminsdk.json /app/data/certs/firebase_service_account.json
```

### 8. Configure Push Proxy

Edit `/app/data/config/mattermost-push-proxy.json`:

```json
{
  "ApplePushSettings": [
    {
      "ApplePushTopic": "YOUR_IOS_BUNDLE_ID",
      "AppleAuthKeyID": "YOUR_KEY_ID",
      "AppleTeamID": "YOUR_TEAM_ID"
    }
  ]
}
```

Restart the app in Cloudron.

### 9. Configure Mattermost Server

System Console → Environment → Push Notification Server:
- Select "Manually enter location"
- Enter: `https://push.yourdomain.com`
- Save

### 10. Test!

1. Install mobile app on device
2. Login to Mattermost
3. Put app in background
4. Send yourself a message
5. Verify push notification received

## Troubleshooting

If notifications don't work:

1. **Check push proxy logs**
   ```bash
   cloudron logs --server my.yourdomain.com --app push.yourdomain.com
   ```

2. **Verify health check**
   ```bash
   curl https://push.yourdomain.com/api/v1/health
   ```

3. **Check bundle IDs match**
   - Mobile app bundle ID
   - Push proxy `ApplePushTopic`
   - Apple Developer portal

4. **Check Mattermost server config**
   - System Console → Push Notification Server
   - Should be `https://push.yourdomain.com`

## Documentation

- **Full guide**: `SETUP_GUIDE.md`
- **README**: `README.md`
- **Official docs**: https://developers.mattermost.com/contribute/mobile/push-notifications/service/

## Questions?

- Check `SETUP_GUIDE.md` for detailed instructions
- Check Mattermost forums: https://forum.mattermost.com/
- Check push proxy logs for errors
