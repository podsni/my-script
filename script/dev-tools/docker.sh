#!/bin/bash

# Docker Installation Script for Ubuntu/Debian
# This script automatically detects the current user and installs Docker with proper permissions
# Author: Assistant
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_warning "Please run as a regular user. The script will use sudo when needed."
        exit 1
    fi
}

# Function to detect current user and system info
detect_system() {
    print_status "Detecting system information..."
    
    CURRENT_USER=$(whoami)
    USER_ID=$(id -u)
    USER_GROUPS=$(groups)
    DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
    VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
    ARCH=$(uname -m)
    
    print_success "System Information:"
    echo "  Current User: $CURRENT_USER (ID: $USER_ID)"
    echo "  Current Groups: $USER_GROUPS"
    echo "  Distribution: $DISTRO $VERSION"
    echo "  Architecture: $ARCH"
    echo ""
}

# Function to check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Unknown")
        print_warning "Docker is already installed: $DOCKER_VERSION"
        
        read -p "Do you want to reinstall Docker? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping Docker installation..."
            configure_docker_permissions
            return 0
        fi
    fi
    return 1
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Update package index
    print_status "Updating package index..."
    sudo apt update
    
    # Install prerequisites
    print_status "Installing prerequisites..."
    sudo apt install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    print_status "Adding Docker's official GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    print_status "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    print_status "Updating package index with Docker repository..."
    sudo apt update
    
    # Install Docker
    print_status "Installing Docker packages..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker installation completed!"
}

# Function to configure Docker permissions
configure_docker_permissions() {
    print_status "Configuring Docker permissions for user: $CURRENT_USER"
    
    # Add user to docker group
    print_status "Adding user to docker group..."
    sudo usermod -aG docker $CURRENT_USER
    
    # Enable and start Docker service
    print_status "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Fix permissions for current session
    print_status "Fixing Docker socket permissions..."
    sudo chmod 666 /var/run/docker.sock
    
    print_success "Docker permissions configured!"
}

# Function to test Docker installation
test_docker() {
    print_status "Testing Docker installation..."
    
    # Test Docker version
    if docker --version &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker version: $DOCKER_VERSION"
    else
        print_error "Docker version check failed!"
        return 1
    fi
    
    # Test Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        print_success "Docker Compose version: $COMPOSE_VERSION"
    else
        print_warning "Docker Compose not available"
    fi
    
    # Test Docker daemon
    print_status "Testing Docker daemon..."
    if docker ps &> /dev/null; then
        print_success "Docker daemon is running and accessible!"
    else
        print_error "Cannot access Docker daemon!"
        return 1
    fi
    
    # Test with hello-world container
    print_status "Testing with hello-world container..."
    if docker run --rm hello-world &> /dev/null; then
        print_success "Docker test completed successfully!"
    else
        print_warning "Hello-world test failed, but Docker is installed"
    fi
}

# Function to show usage instructions
show_usage_instructions() {
    echo ""
    print_success "Docker Installation Complete!"
    echo ""
    echo "Usage Instructions:"
    echo "==================="
    echo ""
    echo "Basic Docker Commands:"
    echo "  docker ps                    # List running containers"
    echo "  docker images               # List downloaded images"
    echo "  docker run <image>          # Run a container"
    echo "  docker pull <image>         # Download an image"
    echo "  docker build -t <name> .    # Build image from Dockerfile"
    echo ""
    echo "Docker Compose Commands:"
    echo "  docker compose up           # Start services"
    echo "  docker compose down         # Stop services"
    echo "  docker compose ps           # List services"
    echo ""
    echo "TryHackMe Examples:"
    echo "  docker run -it ubuntu bash  # Interactive Ubuntu container"
    echo "  docker run -p 8080:80 nginx # Run nginx on port 8080"
    echo ""
    print_warning "Note: You may need to log out and log back in for group changes to take full effect."
    echo "However, the script has already configured permissions for immediate use."
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "    Docker Installation Script v1.0"
    echo "=========================================="
    echo ""
    
    # Check if not running as root
    check_root
    
    # Detect system information
    detect_system
    
    # Check if Docker is already installed
    if ! check_docker_installed; then
        # Install Docker
        install_docker
    fi
    
    # Configure permissions
    configure_docker_permissions
    
    # Test installation
    test_docker
    
    # Show usage instructions
    show_usage_instructions
    
    print_success "Script completed successfully!"
    echo ""
}

# Run main function
main "$@"
