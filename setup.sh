#!/bin/bash

# Linux Security Auditor - Complete Setup Script
# This script sets up the development environment, builds containers, and creates utility scripts

set -e

echo "Linux Security Auditor Complete Setup"
echo "====================================="

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

# Clean up existing containers if they exist and are not running properly
echo -e "\n${YELLOW}[SETUP] Managing existing containers...${NC}"
if docker ps | grep -q "security-test-1\|security-test-2"; then
    echo -e "${YELLOW}WARNING: Existing containers found. Stopping and removing...${NC}"
    docker stop security-test-1 security-test-2 2>/dev/null || true
    docker rm security-test-1 security-test-2 2>/dev/null || true
fi

# Build Docker containers
echo -e "\n${YELLOW}[SETUP] Building Docker test containers...${NC}"

cd docker

echo -e "${BLUE}Building basic test container...${NC}"
docker build -t test-linux . --quiet

echo -e "${BLUE}Building vulnerable test container...${NC}"
docker build -f Dockerfile.vulnerable -t vulnerable-linux . --quiet

echo -e "${GREEN}SUCCESS: Docker images built successfully${NC}"

cd ..

# Start test containers
echo -e "\n${YELLOW}[SETUP] Starting test containers...${NC}"

start_container "security-test-1" "2222" "test-linux"
start_container "security-test-2" "2223" "vulnerable-linux"

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

# Create utility scripts
echo -e "\n${YELLOW}[SETUP] Creating utility scripts...${NC}"

# Create start containers script
cat > start_containers.sh << 'EOF'
#!/bin/bash
echo "Starting Linux Security Auditor test containers..."

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
            echo "SUCCESS: $name is already running"
        else
            echo "Starting existing container: $name"
            docker start "$name"
        fi
    else
        echo "Creating and starting new container: $name"
        docker run -d -p "$port":22 --name "$name" "$image"
    fi
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check if images exist, build if needed
if ! docker image inspect test-linux >/dev/null 2>&1; then
    echo "Building test-linux image..."
    cd docker && docker build -t test-linux . && cd ..
fi

if ! docker image inspect vulnerable-linux >/dev/null 2>&1; then
    echo "Building vulnerable-linux image..."
    cd docker && docker build -f Dockerfile.vulnerable -t vulnerable-linux . && cd ..
fi

# Start containers
start_container "security-test-1" "2222" "test-linux"
start_container "security-test-2" "2223" "vulnerable-linux"

# Wait a moment for containers to fully start
sleep 3

# Verify containers are running
if docker ps | grep -q "security-test-1" && docker ps | grep -q "security-test-2"; then
    echo "SUCCESS: Both containers are running"
    echo "  • Container 1 (basic): localhost:2222"
    echo "  • Container 2 (vulnerable): localhost:2223"
    echo "Ready for security scanning!"
else
    echo "WARNING: One or more containers failed to start"
    docker ps
fi
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

# Auto-start containers if they're not running
echo "Checking container status..."
./start_containers.sh

echo ""
echo "Navigate to: http://127.0.0.1:5000"
echo "Ready for security scanning!"
echo ""
echo "Features available:"
echo "  • SSH key and password authentication"
echo "  • Network port scanning"
echo "  • System configuration auditing"
echo "  • Compliance framework reporting"
echo "  • Scan history tracking"
echo ""
cd src
python3 run.py
EOF

# Create run CLI script  
cat > run_cli.sh << 'EOF'
#!/bin/bash
echo "Running Linux Security Auditor CLI scan..."

# Ensure containers are running
./start_containers.sh

echo ""
echo "Running CLI scan on test container..."
cd src
python3 main.py
EOF

# Create reset script for complete cleanup
cat > reset.sh << 'EOF'
#!/bin/bash
echo "Resetting Linux Security Auditor environment..."

# Stop and remove containers
docker stop security-test-1 security-test-2 2>/dev/null || true
docker rm security-test-1 security-test-2 2>/dev/null || true

# Remove images (optional - uncomment if you want to rebuild everything)
# docker rmi test-linux vulnerable-linux 2>/dev/null || true

# Clean up scan data
rm -f security_report.json scan_history.json scan_configs.json

echo "Environment reset complete. Run ./setup.sh to rebuild."
EOF

# Make scripts executable
chmod +x start_containers.sh stop_containers.sh run_web.sh run_cli.sh reset.sh

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
echo -e "   • Reset:  ${YELLOW}./reset.sh${NC}"
echo -e "\n${BLUE}Test Targets:${NC}"
echo -e "   • Container 1 (basic):      localhost:2222"
echo -e "   • Container 2 (vulnerable): localhost:2223"
echo -e "   • Credentials: root/password"
echo -e "\n${BLUE}Features Available:${NC}"
echo -e "   • SSH configuration scanning"
echo -e "   • System security auditing"
echo -e "   • Network port scanning"
echo -e "   • SSH key authentication support"
echo -e "   • Compliance framework reporting"
echo -e "\n${YELLOW}INFO: Open http://127.0.0.1:5000 to access the web interface${NC}"
echo -e "${YELLOW}INFO: Containers are running and ready for scanning!${NC}"
