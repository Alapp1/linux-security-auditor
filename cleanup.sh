# Check what's using the ports
lsof -i :2222
lsof -i :2223

# OR on some systems:
netstat -tulpn | grep :2222
netstat -tulpn | grep :2223

# Kill any processes using these ports (if found)
sudo lsof -ti:2222 | xargs kill -9
sudo lsof -ti:2223 | xargs kill -9

# Check for any hidden containers with these ports
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep 222

# Force remove any containers using these ports
docker ps -a | grep 222 | awk '{print $1}' | xargs docker rm -f

# Also try removing by port mapping
docker ps -a --format "table {{.Names}}\t{{.Ports}}" | grep 222
