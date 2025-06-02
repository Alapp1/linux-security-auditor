#!/bin/bash

# Linux Security Auditor - Complete Setup Script
# This script sets up the development environment and starts containers

set -e

echo "Linux Security Auditor Setup"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="Linux"
else
    echo -e "${RED}ERROR: Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${BLUE}[INFO] Detected platform: $PLATFORM${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if container exists
container_exists() {
    docker ps -a --format 'table {{.Names}}' | grep -q "^$1$"
}

# Function to check if container is running
container_running() {
    docker ps --format 'table {{.Names}}' | grep -q "^$1$"
}

# Function to start or create container
start_container() {
    local name=$1
    local port=$2
    local image=$3
    
    if container_exists "$name"; then
        if container_running "$name"; then
            echo -e "${GREEN}SUCCESS: $name is already running${NC}"
        else
            echo -e "${BLUE}Starting existing container: $name${NC}"
            docker start "$name"
        fi
    else
        echo -e "${BLUE}Creating and starting new container: $name${NC}"
        docker run -d -p "$port":22 --name "$name" "$image"
    fi
}

# Check and install Python dependencies
echo -e "\n${YELLOW}[SETUP] Checking Python installation...${NC}"
if command_exists python3; then
    echo -e "${GREEN}SUCCESS: Python3 found${NC}"
else
    echo -e "${RED}ERROR: Python3 not found. Please install Python 3.7+${NC}"
    exit 1
fi

if command_exists pip3; then
    echo -e "${GREEN}SUCCESS: pip3 found${NC}"
else
    echo -e "${RED}ERROR: pip3 not found. Please install pip3${NC}"
    exit 1
fi

# Install Python requirements
echo -e "\n${YELLOW}[SETUP] Installing Python dependencies...${NC}"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo -e "${GREEN}SUCCESS: Python packages installed${NC}"
else
    echo -e "${RED}ERROR: requirements.txt not found${NC}"
    exit 1
fi

# Check Docker installation
echo -e "\n${YELLOW}[SETUP] Checking Docker installation...${NC}"
if command_exists docker; then
    echo -e "${GREEN}SUCCESS: Docker found${NC}"
    
    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}SUCCESS: Docker is running${NC}"
    else
        echo -e "${RED}ERROR: Docker is not running${NC}"
        if [[ "$PLATFORM" == "macOS" ]]; then
            echo -e "${YELLOW}INFO: Please start Docker Desktop${NC}"
        else
            echo -e "${YELLOW}INFO: Please start Docker service: sudo systemctl start docker${NC}"
        fi
        exit 1
    fi
else
    echo -e "${RED}ERROR: Docker not found${NC}"
    echo -e "${YELLOW}INFO: Please install Docker:${NC}"
    if [[ "$PLATFORM" == "macOS" ]]; then
        echo -e "   • Download Docker Desktop from https://www.docker.com/products/docker-desktop"
    else
        echo -e "   • Install Docker: https://docs.docker.com/engine/install/"
    fi
    exit 1
fi

# Clean up existing containers if needed
echo -e "\n${YELLOW}[SETUP] Cleaning up existing containers...${NC}"
if docker ps -a | grep -q "security-test-1\|security-test-2"; then
    echo -e "${YELLOW}INFO: Removing existing test containers...${NC}"
    docker stop security-test-1 security-test-2 2>/dev/null || true
    docker rm security-test-1 security-test-2 2>/dev/null || true
fi

# Check if docker directory exists
if [ ! -d "docker" ]; then
    echo -e "${RED}ERROR: docker directory not found${NC}"
    exit 1
fi

# Build Docker containers
echo -e "\n${YELLOW}[SETUP] Building Docker test containers...${NC}"

cd docker

echo -e "${BLUE}Building basic test container...${NC}"
if docker build -t test-linux . --quiet; then
    echo -e "${GREEN}SUCCESS: Basic container built${NC}"
else
    echo -e "${RED}ERROR: Failed to build basic container${NC}"
    exit 1
fi

echo -e "${BLUE}Building vulnerable test container...${NC}"
if docker build -f Dockerfile.vulnerable -t vulnerable-linux . --quiet; then
    echo -e "${GREEN}SUCCESS: Vulnerable container built${NC}"
else
    echo -e "${RED}ERROR: Failed to build vulnerable container${NC}"
    exit 1
fi

cd ..

# Start test containers
echo -e "\n${YELLOW}[SETUP] Starting test containers...${NC}"

start_container "security-test-1" "2222" "test-linux"
start_container "security-test-2" "2223" "vulnerable-linux"

# Wait for containers to fully start
echo -e "${BLUE}Waiting for containers to start...${NC}"
sleep 5

# Verify containers are running
echo -e "\n${YELLOW}[TEST] Verifying container status...${NC}"
if docker ps | grep -q "security-test-1" && docker ps | grep -q "security-test-2"; then
    echo -e "${GREEN}SUCCESS: Both containers are running${NC}"
else
    echo -e "${RED}ERROR: Failed to start containers${NC}"
    echo -e "${YELLOW}Current container status:${NC}"
    docker ps
    exit 1
fi

# Test connectivity
echo -e "\n${YELLOW}[TEST] Testing container connectivity...${NC}"

# Check if src directory exists
if [ ! -d "src" ]; then
    echo -e "${RED}ERROR: src directory not found${NC}"
    exit 1
fi

cd src

# Test SSH connectivity to both containers
python3 -c "
import paramiko
import sys

def test_connection(host, port, name):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, port=port, username='root', password='password', timeout=10)
        ssh.close()
        print(f'SUCCESS: {name} connection test passed')
        return True
    except Exception as e:
        print(f'ERROR: {name} connection failed: {e}')
        return False

print('Testing SSH connectivity...')
success1 = test_connection('localhost', 2222, 'Container 1 (basic)')
success2 = test_connection('localhost', 2223, 'Container 2 (vulnerable)')

if success1 and success2:
    print('SUCCESS: All connectivity tests passed')
else:
    print('ERROR: One or more connectivity tests failed')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: Container connectivity verified${NC}"
else
    echo -e "${RED}ERROR: Container connectivity test failed${NC}"
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo -e "  • Wait a few more seconds and try again"
    echo -e "  • Check if containers are still running: docker ps"
    echo -e "  • Try manual SSH: ssh -p 2222 root@localhost"
    exit 1
fi

cd ..

# Clean up any existing scan data
echo -e "\n${YELLOW}[CLEANUP] Removing old scan data...${NC}"
rm -f security_report.json scan_history.json scan_configs.json *.pdf

# Final success message and instructions
echo -e "\n${GREEN}Setup Complete!${NC}"
echo -e "\n${BLUE}Ready to scan! Open http://127.0.0.1:5000 for the web interface.${NC}"
