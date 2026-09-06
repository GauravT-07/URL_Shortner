#!/bin/bash

set -e

FRONTEND_DIR="$HOME/URL_Shortner/URL_frontend"
WEB_ROOT="/var/www/url-shortener"

echo "=========================================="
echo "Deploying Frontend"
echo "=========================================="

# Go to frontend
cd "$FRONTEND_DIR"

echo ""
echo "[1/4] Building React application..."

npm run build

if [ ! -f "$FRONTEND_DIR/dist/index.html" ]; then
    echo "ERROR: React build failed."
    exit 1
fi

echo "Build successful."

echo ""
echo "[2/4] Copying build to Nginx..."

sudo rm -rf "$WEB_ROOT"/*
sudo cp -r "$FRONTEND_DIR/dist"/. "$WEB_ROOT"/

echo ""
echo "[3/4] Setting permissions..."

sudo chown -R www-data:www-data "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \;

# echo ""
# echo "[4/4] Testing frontend..."

# STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/)

# if [ "$STATUS" = "200" ]; then
#     echo ""
#     echo "=========================================="
#     echo "Frontend deployed successfully!"
#     echo "HTTP Status: $STATUS"
#     echo "=========================================="
# else
#     echo ""
#     echo "ERROR: Frontend returned HTTP $STATUS"
#     exit 1
# fi