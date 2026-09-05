#!/bin/bash

set -e

echo "======================================"
echo "Starting FastAPI backend setup..."
echo "======================================"

# Project paths
PROJECT_DIR="$HOME/URL_Shortner"
BACKEND_DIR="$PROJECT_DIR/URL_backend"
VENV_DIR="$BACKEND_DIR/venv"

# Check backend directory
if [ ! -d "$BACKEND_DIR" ]; then
    echo "ERROR: Backend directory not found:"
    echo "$BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

echo ""
echo "Backend directory:"
pwd

# --------------------------------------------------
# Create virtual environment
# --------------------------------------------------

echo ""
echo "Creating Python virtual environment..."

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# --------------------------------------------------
# Activate virtual environment
# --------------------------------------------------

echo ""
echo "Activating virtual environment..."

source "$VENV_DIR/bin/activate"

# --------------------------------------------------
# Upgrade pip
# --------------------------------------------------

echo ""
echo "Upgrading pip..."

python -m pip install --upgrade pip

# --------------------------------------------------
# Install dependencies
# --------------------------------------------------

echo ""
echo "Installing Python dependencies..."

if [ ! -f "$BACKEND_DIR/requirements.txt" ]; then
    echo "ERROR: requirements.txt not found."
    exit 1
fi

pip install -r requirements.txt

# --------------------------------------------------
# Test FastAPI installation
# --------------------------------------------------

echo ""
echo "Testing FastAPI installation..."

python -c "import fastapi; print('FastAPI version:', fastapi.__version__)"

# --------------------------------------------------
# Create systemd service
# --------------------------------------------------

echo ""
echo "Creating systemd service..."

sudo tee /etc/systemd/system/url-shortener.service > /dev/null <<EOF
[Unit]
Description=URL Shortener FastAPI Backend
After=network.target

[Service]
User=$USER
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------------------
# Enable and start service
# --------------------------------------------------

echo ""
echo "Reloading systemd..."

sudo systemctl daemon-reload

echo ""
echo "Enabling URL Shortener backend..."

sudo systemctl enable url-shortener

echo ""
echo "Starting URL Shortener backend..."

sudo systemctl start url-shortener

# --------------------------------------------------
# Check status
# --------------------------------------------------

echo ""
echo "======================================"
echo "Backend service status"
echo "======================================"

sudo systemctl status url-shortener --no-pager

echo ""
echo "======================================"
echo "FastAPI backend setup completed!"
echo "======================================"

echo ""
echo "Backend should be running on:"
echo "http://YOUR_EC2_PUBLIC_IP:8000"

echo ""
echo "Useful commands:"
echo "sudo systemctl status url-shortener"
echo "sudo systemctl restart url-shortener"
echo "sudo systemctl stop url-shortener"
echo "sudo journalctl -u url-shortener -f"