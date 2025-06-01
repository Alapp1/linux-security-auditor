#!/bin/bash

# Linux Security Auditor - Setup Script
# This script sets up the development environment and test containers

set -e

echo "Linux Security Auditor Setup"
echo "============================="

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

# Check and install Python dependencies
echo -e "\n${YELLOW}[SETUP] Installing Python dependencies...${NC}"
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
echo -e "${BLUE}Installing Python packages...${NC}"
pip3 install -r requirements.txt

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

# Build Docker containers
echo -e "\n${YELLOW}[SETUP] Building Docker test containers...${NC}"

# Check if containers already exist and are running
if docker ps | grep -q "security-test-1\|security-test-2"; then
    echo -e "${YELLOW}WARNING: Existing containers found. Stopping and removing...${NC}"
    docker stop security-test-1 security-test-2 2>/dev/null || true
    docker rm security-test-1 security-test-2 2>/dev/null || true
fi

cd docker

echo -e "${BLUE}Building basic test container...${NC}"
docker build -t test-linux . --quiet

echo -e "${BLUE}Building vulnerable test container...${NC}"
docker build -f Dockerfile.vulnerable -t vulnerable-linux . --quiet

echo -e "${GREEN}SUCCESS: Docker images built successfully${NC}"

# Start test containers
echo -e "\n${YELLOW}[SETUP] Starting test containers...${NC}"

echo -e "${BLUE}Starting container 1 (basic) on port 2222...${NC}"
docker run -d -p 2222:22 --name security-test-1 test-linux

echo -e "${BLUE}Starting container 2 (vulnerable) on port 2223...${NC}"
docker run -d -p 2223:22 --name security-test-2 vulnerable-linux

# Wait a moment for containers to fully start
echo -e "${BLUE}Waiting for containers to start...${NC}"
sleep 5

# Verify containers are running
if docker ps | grep -q "security-test-1" && docker ps | grep -q "security-test-2"; then
    echo -e "${GREEN}SUCCESS: Both containers are running${NC}"
else
    echo -e "${RED}ERROR: Failed to start containers${NC}"
    exit 1
fi

cd ..

# Test connectivity
echo -e "\n${YELLOW}[TEST] Testing container connectivity...${NC}"
cd src

# Simple connection test
python3 -c "
import paramiko
import sys

def test_connection(host, port, name):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, port=port, username='root', password='password', timeout=5)
        ssh.close()
        print(f'SUCCESS: {name} connection successful')
        return True
    except Exception as e:
        print(f'ERROR: {name} connection failed: {e}')
        return False

success1 = test_connection('localhost', 2222, 'Container 1')
success2 = test_connection('localhost', 2223, 'Container 2')

if not (success1 and success2):
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: Container connectivity test passed${NC}"
else
    echo -e "${RED}ERROR: Container connectivity test failed${NC}"
    exit 1
fi

cd ..

# Create useful aliases/scripts
echo -e "\n${YELLOW}[SETUP] Creating utility scripts...${NC}"

# Create start script
cat > start_containers.sh << 'EOF'
#!/bin/bash
echo "Starting Linux Security Auditor test containers..."
docker start security-test-1 security-test-2 2>/dev/null || {
    echo "WARNING: Containers don't exist. Running setup..."
    ./setup.sh
}
echo "SUCCESS: Containers are running:"
echo "   • Container 1 (basic): localhost:2222"
echo "   • Container 2 (vulnerable): localhost:2223"
EOF

# Create stop script
cat > stop_containers.sh << 'EOF'
#!/bin/bash
echo "Stopping Linux Security Auditor test containers..."
docker stop security-test-1 security-test-2 2>/dev/null || echo "Containers not running"
echo "SUCCESS: Containers stopped"
EOF

# Create run web app script
cat > run_web.sh << 'EOF'
#!/bin/bash
echo "Starting Linux Security Auditor Web Interface..."
echo "Navigate to: http://127.0.0.1:5000"
cd src
python3 run.py
EOF

# Create run CLI script  
cat > run_cli.sh << 'EOF'
#!/bin/bash
echo "Running Linux Security Auditor CLI scan..."
cd src
python3 main.py
EOF

# Make scripts executable
chmod +x start_containers.sh stop_containers.sh run_web.sh run_cli.sh

echo -e "${GREEN}SUCCESS: Utility scripts created${NC}"

# Final success message
echo -e "\n${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}===============${NC}"
echo -e "\n${BLUE}Quick Start:${NC}"
echo -e "   • Web Interface: ${YELLOW}./run_web.sh${NC}"
echo -e "   • CLI Scan:      ${YELLOW}./run_cli.sh${NC}"
echo -e "\n${BLUE}Container Management:${NC}"
echo -e "   • Start:  ${YELLOW}./start_containers.sh${NC}"
echo -e "   • Stop:   ${YELLOW}./stop_containers.sh${NC}"
echo -e "\n${BLUE}Test Targets:${NC}"
echo -e "   • Container 1 (basic):      localhost:2222"
echo -e "   • Container 2 (vulnerable): localhost:2223"
echo -e "   • Credentials: root/password"
echo -e "\n${YELLOW}INFO: Open http://127.0.0.1:5000 to access the web interface${NC}"
