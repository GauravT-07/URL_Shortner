#!/bin/bash

set -e

echo "======================================"
echo "Starting EC2 setup..."
echo "======================================"

# Update system
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install required packages
echo "Installing Git and Python..."
sudo apt install -y git python3 python3-pip python3-venv

# Verify installations
echo ""
echo "Git version:"
git --version

echo ""
echo "Python version:"
python3 --version

echo ""
echo "Pip version:"
pip3 --version

# Clone repository
REPO_URL="https://github.com/GauravT-07/URL_Shortner.git"
PROJECT_DIR="$HOME/URL_Shortner"

if [ -d "$PROJECT_DIR" ]; then
    echo ""
    echo "Project directory already exists."
    echo "Skipping git clone."
else
    echo ""
    echo "Cloning repository..."
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

# Move into project
cd "$PROJECT_DIR"

echo ""
echo "Project contents:"
ls -la

echo ""
echo "======================================"
echo "EC2 initial setup completed!"
echo "======================================"

echo ""
echo "Project location:"
pwd