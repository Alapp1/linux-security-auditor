# Linux Security Auditor

A comprehensive security scanning tool for Linux systems that identifies misconfigurations and vulnerabilities across SSH and system configurations. Built with a modern web interface and CLI support.

## Features

- **Interactive Web Dashboard** - Modern, responsive interface for configuring and running scans
- **CLI Support** - Command-line interface for automated scanning and CI/CD integration
- **Multi-Target Scanning** - Scan multiple hosts with custom configurations
- **Scan History** - Track and compare security improvements over time
- **Real-time Results** - Live scan progress with automatic page updates
- **Detailed Reporting** - Comprehensive findings with remediation recommendations
- **Docker Test Environment** - Pre-configured vulnerable containers for testing

## Security Checks

### SSH Configuration

- Root login permissions
- Password authentication settings
- Empty password policies
- Protocol version verification

### System Configuration

- File permission auditing (`/etc/shadow`, world-writable files)
- User account security (empty passwords)
- Critical directory permissions

## Prerequisites

- **Python 3.7+** with pip
- **Docker Desktop** (macOS) or **Docker Engine** (Linux)
- **SSH access** to target systems

## Quick Start

### 1. Clone and Setup

```bash
git clone git@github.com:Alapp1/linux-security-auditor.git
cd linux-security-auditor
chmod +x setup.sh
./setup.sh
```

The setup script will:

- Install Python dependencies
- Verify Docker installation
- Build test containers
- Start vulnerable test environments
- Create utility scripts

### 2. Launch Web Interface

```bash
./run_web.sh
```

Navigate to `http://127.0.0.1:5000`

### 3. Run CLI Scan

```bash
./run_cli.sh
```

## Test Environment

The project includes two pre-configured Docker containers for testing:

| Container       | Port | Security Level | Purpose                                   |
| --------------- | ---- | -------------- | ----------------------------------------- |
| security-test-1 | 2222 | Basic          | Standard configuration with common issues |
| security-test-2 | 2223 | Vulnerable     | Intentionally misconfigured for testing   |

**Default Credentials:** `root` / `password`

## Project Structure

```
linux-security-auditor/
├── src/
│   ├── app/                    # Flask web application
│   │   ├── __init__.py         # App factory
│   │   ├── routes.py           # Web routes and endpoints
│   │   ├── models.py           # Data models and scan logic
│   │   └── templates/
│   │       └── dashboard.html  # Web interface
│   ├── scanner_base.py         # Base scanner classes
│   ├── ssh_scanner_v2.py       # SSH configuration scanner
│   ├── system_scanner.py       # System configuration scanner
│   ├── main.py                 # CLI interface
│   └── run.py                  # Web app entry point
├── docker/
│   ├── Dockerfile              # Basic test container
│   └── Dockerfile.vulnerable   # Vulnerable test container
├── tests/                      # Unit tests (future)
├── requirements.txt            # Python dependencies
├── setup.sh                    # Automated setup script
└── README.md                   # This file
```

## Usage

### Web Interface

1. **Configure Target:** Enter hostname, port, and credentials
2. **Quick Presets:** Use preset buttons for test containers
3. **Run Scan:** Click "Start Security Scan"
4. **View Results:** Real-time findings with severity levels
5. **Scan History:** Browse previous scans in the sidebar

### CLI Interface

```bash
cd src
python3 main.py
```

Outputs structured findings to terminal and saves `security_report.json`.

### Container Management

```bash
# Start test containers
./start_containers.sh

# Stop test containers
./stop_containers.sh

# View container status
docker ps
```

## Sample Output

### Web Dashboard

- **Visual Statistics:** Critical, High, Medium severity counts
- **Detailed Findings:** Issue descriptions with remediation steps
- **Historical Tracking:** Compare scans over time
- **Interactive Forms:** Easy target configuration

### CLI Output

```
Starting security audit of localhost:2222
==================================================
Scanning SSH configuration...
Scanning system configuration...

SECURITY AUDIT COMPLETE
Total findings: 3
==================================================

CRITICAL ISSUES (1):
  • Root login is enabled
    → Set 'PermitRootLogin no' in /etc/ssh/sshd_config

HIGH PRIORITY (2):
  • Password authentication enabled
    → Use SSH keys and set 'PasswordAuthentication no'
```

## Development

### Adding New Scanners

1. **Create Scanner Class:**

```python
from scanner_base import SecurityScanner, Finding

class MyScanner(SecurityScanner):
    def scan(self):
        findings = []
        # Add your scanning logic
        return findings
```

2. **Register in Models:**

```python
# In app/models.py SecurityScanner.run_scan()
my_scanner = MyScanner(host, port, username, password)
my_results = my_scanner.scan()
all_findings.extend(my_results)
```

### Running Tests

```bash
cd src
python3 -m pytest tests/  # When test suite is implemented
```

## Deployment

### Local Development

```bash
./run_web.sh
```

### Production Deployment

```bash
cd src
export FLASK_ENV=production
gunicorn -w 4 -b 0.0.0.0:8000 'app:create_app()'
```

## Configuration

### Custom Scan Targets

Edit targets directly in the web interface or modify `app/models.py` for programmatic configuration.

### Security Checks

Extend scanning capabilities by:

- Adding new scanner classes in separate files
- Implementing additional check types in existing scanners
- Customizing severity levels and recommendations

## Security Considerations

- **Credentials:** Never store production credentials in code
- **Network Access:** Ensure proper network segmentation for scan targets
- **Permissions:** Run with minimal required privileges
- **Audit Logs:** Consider logging scan activities for compliance

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

**Docker containers won't start:**

```bash
# Check Docker status
docker info

# Restart Docker service (Linux)
sudo systemctl restart docker

# On macOS, restart Docker Desktop
```

**SSH connection failures:**

```bash
# Verify containers are running
docker ps

# Check port availability
netstat -an | grep :2222

# Test manual SSH connection
ssh -p 2222 root@localhost
```

**Python dependency issues:**

```bash
# Upgrade pip
pip3 install --upgrade pip

# Reinstall requirements
pip3 install -r requirements.txt --force-reinstall
```

### Getting Help

1. Check the troubleshooting section above
2. Review Docker and SSH connectivity
3. Verify Python dependencies are installed
4. Check that test containers are running on correct ports
