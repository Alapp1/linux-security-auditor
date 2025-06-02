#!/bin/bash

# Linux Security Auditor - Complete Cleanup Script
# This script thoroughly cleans up containers, ports, and project files

set -e

echo "Linux Security Auditor Cleanup"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}[CLEANUP] Starting comprehensive cleanup...${NC}"

# 1. Stop and remove specific containers
echo -e "\n${BLUE}[STEP 1] Stopping and removing security test containers...${NC}"
if command_exists docker; then
    # Stop containers by name
    for container in security-test-1 security-test-2; do
        if docker ps -q -f name="$container" | grep -q .; then
            echo -e "${YELLOW}Stopping container: $container${NC}"
            docker stop "$container" 2>/dev/null || true
        fi
        
        if docker ps -aq -f name="$container" | grep -q .; then
            echo -e "${YELLOW}Removing container: $container${NC}"
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    # Also check for any containers using our ports
    echo -e "${BLUE}Checking for containers using ports 2222 and 2223...${NC}"
    
    # Find containers by port mapping
    containers_using_ports=$(docker ps -a --format "table {{.Names}}\t{{.Ports}}" | grep -E "222[23]" | awk '{print $1}' | grep -v NAMES || true)
    
    if [ ! -z "$containers_using_ports" ]; then
        echo -e "${YELLOW}Found containers using our ports, removing them:${NC}"
        for container in $containers_using_ports; do
            echo -e "${YELLOW}Force removing: $container${NC}"
            docker stop "$container" 2>/dev/null || true
            docker rm -f "$container" 2>/dev/null || true
        done
    fi
    
    echo -e "${GREEN}SUCCESS: Container cleanup completed${NC}"
else
    echo -e "${YELLOW}WARNING: Docker not found, skipping container cleanup${NC}"
fi

# 2. Check and clean up ports
echo -e "\n${BLUE}[STEP 2] Checking port usage...${NC}"

for port in 2222 2223 5000; do
    echo -e "${BLUE}Checking port $port...${NC}"
    
    if command_exists lsof; then
        # Using lsof (macOS/Linux)
        processes=$(lsof -ti:$port 2>/dev/null || true)
        if [ ! -z "$processes" ]; then
            echo -e "${YELLOW}Found processes using port $port:${NC}"
            lsof -i :$port || true
            echo -e "${YELLOW}Killing processes on port $port...${NC}"
            sudo lsof -ti:$port | xargs kill -9 2>/dev/null || true
        else
            echo -e "${GREEN}Port $port is free${NC}"
        fi
    elif command_exists netstat; then
        # Using netstat (Linux fallback)
        processes=$(netstat -tulpn 2>/dev/null | grep ":$port " || true)
        if [ ! -z "$processes" ]; then
            echo -e "${YELLOW}Found processes using port $port:${NC}"
            echo "$processes"
            # Extract PIDs and kill them
            pids=$(echo "$processes" | awk '{print $7}' | cut -d'/' -f1 | grep -E '^[0-9]+$' || true)
            if [ ! -z "$pids" ]; then
                echo -e "${YELLOW}Killing PIDs: $pids${NC}"
                sudo kill -9 $pids 2>/dev/null || true
            fi
        else
            echo -e "${GREEN}Port $port is free${NC}"
        fi
    else
        echo -e "${YELLOW}WARNING: Neither lsof nor netstat available, cannot check port $port${NC}"
    fi
done

# 3. Remove Docker images (optional)
echo -e "\n${BLUE}[STEP 3] Docker image cleanup...${NC}"
if command_exists docker; then
    # List our specific images
    images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | grep -E "test-linux|vulnerable-linux" || true)
    
    if [ ! -z "$images" ]; then
        echo -e "${YELLOW}Found security test images:${NC}"
        echo "$images"
        read -p "Remove these Docker images? (y/N): " remove_images
        if [[ $remove_images =~ ^[Yy]$ ]]; then
            docker rmi test-linux vulnerable-linux 2>/dev/null || true
            echo -e "${GREEN}SUCCESS: Images removed${NC}"
        else
            echo -e "${BLUE}INFO: Keeping Docker images${NC}"
        fi
    else
        echo -e "${GREEN}No security test images found${NC}"
    fi
fi

# 4. Clean up project files
echo -e "\n${BLUE}[STEP 4] Cleaning up project files...${NC}"

# Remove generated files
files_to_remove=(
    "security_report.json"
    "scan_history.json" 
    "scan_configs.json"
    "*.pdf"
    "src/__pycache__"
    "src/app/__pycache__"
)

for pattern in "${files_to_remove[@]}"; do
    if ls $pattern 1> /dev/null 2>&1; then
        echo -e "${YELLOW}Removing: $pattern${NC}"
        rm -rf $pattern
    fi
done

# 5. Clean up Python cache
echo -e "\n${BLUE}[STEP 5] Cleaning Python cache...${NC}"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true

# 6. Final verification
echo -e "\n${BLUE}[STEP 6] Final verification...${NC}"

echo -e "${BLUE}Checking container status:${NC}"
if command_exists docker; then
    containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "security-test|222[23]" || true)
    if [ ! -z "$containers" ]; then
        echo -e "${YELLOW}WARNING: Found remaining containers:${NC}"
        echo "$containers"
    else
        echo -e "${GREEN}SUCCESS: No security test containers found${NC}"
    fi
fi

echo -e "${BLUE}Checking port status:${NC}"
for port in 2222 2223; do
    if command_exists lsof; then
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${YELLOW}WARNING: Port $port still in use${NC}"
            lsof -i :$port
        else
            echo -e "${GREEN}SUCCESS: Port $port is free${NC}"
        fi
    fi
done

# 7. Reset permissions (if needed)
echo -e "\n${BLUE}[STEP 7] Resetting permissions...${NC}"
chmod +x setup.sh cleanup.sh 2>/dev/null || true

# Final message
echo -e "\n${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}=================${NC}"
echo -e "\n${BLUE}Environment Status:${NC}"
echo -e "   ✓ Containers stopped and removed"
echo -e "   ✓ Ports 2222, 2223 freed"
echo -e "   ✓ Project files cleaned"
echo -e "   ✓ Python cache cleared"
echo -e "\n${YELLOW}Ready for fresh setup!${NC}"
echo -e "Run ${GREEN}./setup.sh${NC} to rebuild the environment"
