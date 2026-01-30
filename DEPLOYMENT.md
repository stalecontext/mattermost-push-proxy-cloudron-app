# Push Proxy Deployment Workflow

Quick reference for deploying the Mattermost Push Proxy to Cloudron.

## Your Setup

- **Cloudron Dashboard**: https://my.sourcemod.xyz
- **Push Proxy URL**: https://push.sourcemod.xyz
- **Mattermost Server**: https://chat.sourcemod.xyz
- **Docker Hub**: stalecontext/mattermost-push-proxy-cloudron

## First-Time Installation

### 1. Prerequisites

- Docker Desktop running and logged in: `docker login`
- Cloudron CLI installed: `npm install -g cloudron`
- Cloudron CLI logged in: `cloudron login`
- Push certificates ready (see SETUP_GUIDE.md)

### 2. Install to Cloudron

```bash
cd G:\Modding\_Github\mattermost-push-proxy-cloudron-app

# Build, push to Docker Hub, and install to Cloudron
.\install-cloudron.bat 6.4.6
```

This script will:
- Fix line endings in start.sh
- Update Dockerfile with version 6.4.6
- Build Docker image
- Push to Docker Hub as `stalecontext/mattermost-push-proxy-cloudron:0.1.0`
- Install to Cloudron at `push.sourcemod.xyz`

### 3. Upload Certificates

After installation completes:

```bash
# Upload iOS Auth Key
cloudron push --app push.sourcemod.xyz AuthKey_XXXXXXXXXX.p8 /app/data/certs/apple_auth_key.p8

# Upload Android Service Account
cloudron push --app push.sourcemod.xyz firebase-service-account.json /app/data/certs/firebase_service_account.json
```

### 4. Configure Push Proxy

Via Cloudron Web Terminal:
1. Go to https://my.sourcemod.xyz
2. Open Push Proxy app
3. Click "Terminal" tab
4. Edit config:
   ```bash
   vi /app/data/config/mattermost-push-proxy.json
   ```

Update these values:
```json
{
  "ApplePushSettings": [
    {
      "ApplePushTopic": "com.yourcompany.mattermost",
      "AppleAuthKeyID": "AB12CD34EF",
      "AppleTeamID": "XYZ1234567"
    }
  ]
}
```

### 5. Restart App

In Cloudron dashboard → Push Proxy app → Click "Restart"

### 6. Verify

```bash
curl https://push.sourcemod.xyz/api/v1/health
# Should return: {"status":"ok"}
```

### 7. Configure Mattermost Server

System Console → Environment → Push Notification Server:
- Select "Manually enter location"
- Enter: `https://push.sourcemod.xyz`
- Save

## Updating to New Version

When upstream push proxy releases a new version:

```bash
cd G:\Modding\_Github\mattermost-push-proxy-cloudron-app

# Option 1: Build and push, then click UPDATE in Cloudron UI
.\deploy.bat 6.5.0
# Wait for Docker Hub push to complete
# Go to Cloudron dashboard → Push Proxy app → Click UPDATE

# Option 2: Direct update (faster, bypasses Cloudron UI)
.\update-cloudron.bat 0.2.0
```

## Scripts Reference

| Script | Purpose | Commit to Git? |
|--------|---------|----------------|
| `configure-cloudron.bat` | One-time Docker Hub setup | ✅ Yes (prompts for input) |
| `deploy.bat` | Build and push to Docker Hub | ✅ Yes (reads from config) |
| `install-cloudron.bat` | First-time app installation | ❌ No (contains domain) |
| `update-cloudron.bat` | Direct app update | ❌ No (contains domain) |
| `cloudron-wrapper.bat` | Environment wrapper | ✅ Yes |

## Troubleshooting

### App won't install

Check if app already exists:
```bash
cloudron list | findstr push
```

If it exists, use `update-cloudron.bat` instead.

### Docker build fails

Check Docker is running:
```bash
docker info
```

Check line endings:
```bash
# In Git Bash or WSL
file start.sh
# Should show: start.sh: ASCII text
# NOT: start.sh: ASCII text, with CRLF line terminators
```

### Push notifications not working

1. Check push proxy logs:
   ```bash
   cloudron logs --app push.sourcemod.xyz
   ```

2. Verify certificates are uploaded:
   ```bash
   cloudron exec --app push.sourcemod.xyz -- ls -la /app/data/certs/
   ```

3. Verify config:
   ```bash
   cloudron exec --app push.sourcemod.xyz -- cat /app/data/config/mattermost-push-proxy.json
   ```

4. Check bundle IDs match:
   - iOS app bundle ID
   - `ApplePushTopic` in push proxy config
   - Apple Developer portal certificate

5. Verify Mattermost server config:
   - System Console → Push Notification Server
   - Should be: `https://push.sourcemod.xyz`

## File Locations on Server

Inside the Cloudron app container:

```
/app/code/                              # Push proxy binary
├── bin/
│   └── mattermost-push-proxy           # Main executable
└── config/                             # Default config (not used)

/app/data/                              # Persistent data
├── certs/
│   ├── apple_auth_key.p8               # iOS certificate
│   └── firebase_service_account.json   # Android certificate
└── config/
    └── mattermost-push-proxy.json      # Active config
```

## Health Check

The app health check endpoint is configured in CloudronManifest.json:

```json
"healthCheckPath": "/api/v1/health"
```

Cloudron automatically monitors this endpoint. If it returns anything other than `{"status":"ok"}`, the app is marked as unhealthy.

## Version Numbers

- **CloudronManifest.json version**: Cloudron package version (e.g., `0.1.0`)
- **upstreamVersion**: Push proxy version (e.g., `6.4.6`)
- **Docker tags**: Both versions are pushed
  - `stalecontext/mattermost-push-proxy-cloudron:0.1.0`
  - `stalecontext/mattermost-push-proxy-cloudron:latest`

Increment CloudronManifest.json version when making changes to the Cloudron package (Dockerfile, start.sh, etc.).

## Next Steps

See:
- **SETUP_GUIDE.md** - Complete setup instructions with certificate generation
- **NEXT_STEPS.md** - Quick checklist
- **README.md** - Package overview
