# Linux Security Auditor

A comprehensive security scanning tool for Linux systems that identifies misconfigurations and vulnerabilities across SSH, system, and network configurations. Built with a modern web interface and CLI support.

## Features

- **Interactive Web Dashboard** - Modern, responsive interface for configuring and running scans
- **CLI Support** - Command-line interface for automated scanning and CI/CD integration
- **SSH Key Authentication** - Support for both password and SSH key-based authentication
- **Network Port Scanning** - Identifies open ports and potentially insecure services
- **Scan History** - Track and compare security improvements over time
- **Real-time Results** - Live scan progress with automatic page updates
- **Compliance Reporting** - Findings mapped to security frameworks (CIS, NIST, ISO27001)
- **Docker Test Environment** - Pre-configured vulnerable containers for testing

## Security Checks

### SSH Configuration

- Root login permissions
- Password authentication settings
- Empty password policies
- Weak cipher configurations

### System Configuration

- File permission auditing (`/etc/shadow`, world-writable files)
- User account security (empty passwords)
- Critical directory permissions

### Network Security

- Open port detection
- Insecure service identification
- Database exposure detection
- Telnet/FTP vulnerability scanning

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
│   │   ├── __init__.py        # App factory
│   │   ├── routes.py          # Web routes and endpoints
│   │   ├── models.py          # Data models and scan logic
│   │   └── templates/
│   │       └── dashboard.html # Web interface
│   ├── scanner_base.py        # Base scanner classes
│   ├── ssh_scanner_v2.py      # SSH configuration scanner
│   ├── system_scanner.py      # System configuration scanner
│   ├── network_scanner.py     # Network port scanner
│   ├── main.py               # CLI interface
│   └── run.py                # Web app entry point
├── docker/
│   ├── Dockerfile            # Basic test container
│   └── Dockerfile.vulnerable # Vulnerable test container
├── requirements.txt          # Python dependencies
├── setup.sh                 # Automated setup script
└── README.md                # This file
```

## Usage

### Web Interface

1. **Configure Target:** Enter hostname, port, and credentials
2. **Choose Authentication:** Select password or SSH key authentication
3. **Quick Presets:** Use preset buttons for test containers
4. **Run Scan:** Click "Start Security Scan"
5. **View Results:** Real-time findings with severity levels and compliance mappings
6. **Scan History:** Browse previous scans in the sidebar

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

# Reset environment
./reset.sh

# View container status
docker ps
```

## Sample Output

### Web Dashboard

- **Visual Statistics:** Critical, High, Medium severity counts
- **Detailed Findings:** Issue descriptions with remediation steps
- **Compliance Mapping:** CIS, NIST, and ISO27001 control references
- **Historical Tracking:** Compare scans over time
- **Interactive Forms:** Easy target configuration with authentication tabs

### CLI Output

```
Starting security audit of localhost:2222
==================================================
Scanning SSH configuration...
Scanning system configuration...
Scanning network configuration...

SECURITY AUDIT COMPLETE
Total findings: 4
==================================================

CRITICAL ISSUES (2):
  • Root login is enabled
    → Set 'PermitRootLogin no' in /etc/ssh/sshd_config
  • Users with empty passwords: testuser
    → Set passwords for all users

HIGH PRIORITY (1):
  • Password authentication enabled
    → Use SSH keys and set 'PasswordAuthentication no'

MEDIUM PRIORITY (1):
  • SSH running on non-standard port 2222
    → Non-standard SSH ports provide security through obscurity
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
        findings.append(Finding(
            "HIGH", "MyCategory", "Issue description",
            "Remediation recommendation",
            {"CIS": "1.2.3", "NIST": "AC-4"}
        ))
        return findings
```

2. **Register in Models:**

```python
# In app/models.py SecurityScanner.run_scan()
my_scanner = MyScanner(host, port, username, password, ssh_key_path)
my_results = my_scanner.scan()
all_findings.extend(my_results)
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

Configure targets directly in the web interface using:

- **Target Name:** Descriptive name for the system
- **Host/IP:** Target system address
- **SSH Port:** Custom SSH port (default: 22)
- **Authentication:** Password or SSH key path

### Security Checks

Extend scanning capabilities by:

- Adding new scanner classes in separate files
- Implementing additional check types in existing scanners
- Customizing severity levels and compliance mappings
- Adding new compliance frameworks

## Security Considerations

- **Credentials:** Never store production credentials in code
- **Network Access:** Ensure proper network segmentation for scan targets
- **Permissions:** Run with minimal required privileges
- **Audit Logs:** Consider logging scan activities for compliance
- **SSH Keys:** Store private keys securely with proper file permissions

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

**Port conflicts:**

```bash
# Use the reset script for complete cleanup
./reset.sh

# Then rebuild
./setup.sh
```

### Getting Help

1. Check the troubleshooting section above
2. Review Docker and SSH connectivity
3. Verify Python dependencies are installed
4. Check that test containers are running on correct ports
