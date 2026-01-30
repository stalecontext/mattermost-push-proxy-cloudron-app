# Mattermost Push Proxy

The Mattermost Push Notification Service (MPNS) is required for custom Mattermost mobile applications to receive push notifications.

## Features

- Relays push notifications to Apple Push Notification Service (APNS)
- Relays push notifications to Firebase Cloud Messaging (FCM)
- Throttling and rate limiting
- Health check endpoint
- Metrics support

## Configuration

This service requires:

1. **iOS Push Certificates**: Apple Push Notification certificate or Auth Key for your iOS app
2. **Android Service File**: Firebase service account JSON file for your Android app

These files should be uploaded to the `/app/data/certs` directory after installation.

## Usage

After deploying this app, configure your Mattermost server to use this push proxy:

1. Go to **System Console > Environment > Push Notification Server**
2. Select **"Manually enter Push Notification Service location"**
3. Enter: `https://your-push-proxy-domain.com`
4. Save changes

## Documentation

See [Mattermost Push Notification Service documentation](https://developers.mattermost.com/contribute/mobile/push-notifications/service/) for more information.
