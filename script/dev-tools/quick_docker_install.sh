#!/bin/bash

# Quick Docker Installation Script
# Simple version for fresh Docker installation
# Usage: ./quick_docker_install.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐳 Quick Docker Installation Script${NC}"
echo "=================================="
echo ""

# Detect current user
CURRENT_USER=$(whoami)
echo -e "${BLUE}Detected user: $CURRENT_USER${NC}"
echo ""

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is already installed!${NC}"
    docker --version
    echo ""
    echo "Testing Docker without sudo..."
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✅ Docker works without sudo!${NC}"
    else
        echo -e "${BLUE}🔧 Fixing Docker permissions...${NC}"
        sudo usermod -aG docker $CURRENT_USER
        sudo chmod 666 /var/run/docker.sock
        echo -e "${GREEN}✅ Docker permissions fixed!${NC}"
    fi
    exit 0
fi

echo -e "${BLUE}📦 Installing Docker...${NC}"

# Update system
sudo apt update

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure permissions
echo -e "${BLUE}🔧 Configuring Docker permissions...${NC}"
sudo usermod -aG docker $CURRENT_USER
sudo systemctl enable docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

# Test installation
echo -e "${BLUE}🧪 Testing Docker installation...${NC}"
docker --version
docker compose version

# Test without sudo
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker works without sudo!${NC}"
else
    echo -e "${BLUE}⚠️  You may need to log out and log back in for full group access${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Docker installation completed!${NC}"
echo ""
echo "Quick commands:"
echo "  docker ps          # List containers"
echo "  docker images       # List images"
echo "  docker run hello-world  # Test Docker"
echo ""
