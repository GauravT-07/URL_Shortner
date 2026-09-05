#!/bin/bash

set -e

# =========================================================
# URL Shortener - Frontend EC2 Setup
# =========================================================

PROJECT_DIR="$HOME/URL_Shortner"
FRONTEND_DIR="$PROJECT_DIR/URL_frontend"

WEB_ROOT="/var/www/url-shortener"
NGINX_CONFIG="/etc/nginx/sites-available/url-shortener"
NGINX_ENABLED="/etc/nginx/sites-enabled/url-shortener"

echo "=================================================="
echo "URL Shortener - Frontend EC2 Setup"
echo "=================================================="

# =========================================================
# 1. Validate project
# =========================================================

echo ""
echo "[1/10] Validating project..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Project directory not found:"
    echo "$PROJECT_DIR"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "ERROR: Frontend directory not found:"
    echo "$FRONTEND_DIR"
    exit 1
fi

echo "Project found."
echo "Frontend found."

# =========================================================
# 2. Update packages
# =========================================================

echo ""
echo "[2/10] Updating Ubuntu packages..."

sudo apt update -y

# =========================================================
# 3. Install required packages
# =========================================================

echo ""
echo "[3/10] Installing required packages..."

sudo apt install -y curl nginx

# =========================================================
# 4. Install Node.js 22
# =========================================================

echo ""
echo "[4/10] Checking Node.js..."

if command -v node >/dev/null 2>&1; then
    echo "Node.js already installed:"
    node --version
else
    echo "Installing Node.js 22..."

    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo ""
echo "Node.js:"
node --version

echo "npm:"
npm --version

# =========================================================
# 5. Configure production environment
# =========================================================

echo ""
echo "[5/10] Configuring React production environment..."

cat > "$FRONTEND_DIR/.env.production" <<EOF
VITE_API_URL=/api
VITE_FRONTEND_URL=
EOF

echo ""
echo "Production environment:"
cat "$FRONTEND_DIR/.env.production"

# =========================================================
# 6. Install frontend dependencies
# =========================================================

echo ""
echo "[6/10] Installing frontend dependencies..."

cd "$FRONTEND_DIR"

npm install

# =========================================================
# 7. Build React application
# =========================================================

echo ""
echo "[7/10] Building React application..."

npm run build

if [ ! -f "$FRONTEND_DIR/dist/index.html" ]; then
    echo "ERROR: React build failed."
    exit 1
fi

echo "React build successful."

# =========================================================
# 8. Copy frontend to Nginx web root
# =========================================================

echo ""
echo "[8/10] Installing frontend into Nginx web root..."

sudo mkdir -p "$WEB_ROOT"

sudo rm -rf "$WEB_ROOT"/*
sudo cp -r "$FRONTEND_DIR/dist"/. "$WEB_ROOT"/

# Nginx needs read access
sudo chown -R www-data:www-data "$WEB_ROOT"

sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \;

echo "Frontend installed at:"
echo "$WEB_ROOT"

# =========================================================
# 9. Configure Nginx
# =========================================================

echo ""
echo "[9/10] Configuring Nginx..."

sudo tee "$NGINX_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    root $WEB_ROOT;
    index index.html;

    # React frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # FastAPI backend
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Remove default Nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Remove old URL Shortener link if it exists
sudo rm -f "$NGINX_ENABLED"

# Enable our configuration
sudo ln -s "$NGINX_CONFIG" "$NGINX_ENABLED"

# =========================================================
# 10. Test and start Nginx
# =========================================================

echo ""
echo "[10/10] Testing and starting Nginx..."

sudo nginx -t

sudo systemctl enable nginx
sudo systemctl restart nginx

# =========================================================
# Verification
# =========================================================

echo ""
echo "=================================================="
echo "Running verification tests"
echo "=================================================="

echo ""
echo "Testing frontend..."

FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/)

if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "Frontend: OK (HTTP $FRONTEND_STATUS)"
else
    echo "ERROR: Frontend returned HTTP $FRONTEND_STATUS"
    exit 1
fi

echo ""
echo "Testing FastAPI through Nginx..."

if curl -s --fail http://127.0.0.1/api/all > /tmp/url_shortener_api_test; then
    echo "FastAPI: OK"
    echo "API response:"
    cat /tmp/url_shortener_api_test
else
    echo "WARNING: FastAPI is not responding through Nginx."
    echo "Make sure the url-shortener systemd service is running."
fi

echo ""
echo "Checking Nginx service..."

if sudo systemctl is-active --quiet nginx; then
    echo "Nginx: active"
else
    echo "ERROR: Nginx is not running."
    exit 1
fi

echo ""
echo "=================================================="
echo "Frontend setup completed successfully!"
echo "=================================================="

echo ""
echo "Frontend:"
echo "$WEB_ROOT"

echo ""
echo "Nginx configuration:"
echo "$NGINX_CONFIG"

echo ""
echo "Local frontend test:"
echo "curl http://127.0.0.1"

echo ""
echo "Local API test:"
echo "curl http://127.0.0.1/api/all"

echo ""
echo "Open in browser:"
echo "http://YOUR_EC2_PUBLIC_IP"

echo ""
echo "IMPORTANT:"
echo "Allow HTTP/TCP port 80 in the EC2 Security Group."

echo ""
echo "Useful commands:"
echo "sudo nginx -t"
echo "sudo systemctl status nginx"
echo "sudo systemctl restart nginx"
echo "sudo tail -f /var/log/nginx/error.log"