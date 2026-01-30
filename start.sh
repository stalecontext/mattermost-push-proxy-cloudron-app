#!/bin/bash

set -eu -o pipefail

echo "=> Setting up Mattermost Push Proxy"

# Create necessary directories
mkdir -p /app/data/certs /app/data/config

# Generate config on first run or copy template
if [[ ! -f /app/data/config/mattermost-push-proxy.json ]]; then
    echo "=> Generating config on first run"

    # Copy template
    cp /app/pkg/config.json.template /app/data/config/mattermost-push-proxy.json

    echo ""
    echo "========================================"
    echo "IMPORTANT: Push Proxy Configuration"
    echo "========================================"
    echo ""
    echo "The push proxy requires certificates to function:"
    echo ""
    echo "1. For iOS (choose one method):"
    echo "   - Apple Push Certificate (.pem): /app/data/certs/apple_push_cert.pem"
    echo "   - OR Apple Auth Key (.p8): /app/data/certs/apple_auth_key.p8"
    echo ""
    echo "2. For Android:"
    echo "   - Firebase Service Account: /app/data/certs/firebase_service_account.json"
    echo ""
    echo "3. Edit configuration:"
    echo "   /app/data/config/mattermost-push-proxy.json"
    echo ""
    echo "   Set these values:"
    echo "   - ApplePushTopic (your iOS bundle ID, e.g., com.yourcompany.mattermost)"
    echo "   - AppleAuthKeyID (if using Auth Key method)"
    echo "   - AppleTeamID (your Apple Team ID)"
    echo ""
    echo "After uploading certificates and editing config, restart this app."
    echo "========================================"
    echo ""
fi

echo "=> Changing ownership"
chown -R cloudron:cloudron /app/data

echo "=> Starting Mattermost Push Proxy"
cd /app/code
exec /usr/local/bin/gosu cloudron:cloudron ./bin/mattermost-push-proxy --config=/app/data/config/mattermost-push-proxy.json
