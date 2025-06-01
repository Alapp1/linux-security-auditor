import json
import os
import sys
import uuid
from datetime import datetime

sys.path.append("..")
from network_scanner import NetworkScanner
from scanner_base import Finding
from ssh_scanner_v2 import SSHScanner
from system_scanner import SystemScanner


class ScanHistory:
    @staticmethod
    def load_history():
        """Load all previous scans"""
        if os.path.exists("scan_history.json"):
            with open("scan_history.json", "r") as f:
                return json.load(f)
        return []

    @staticmethod
    def save_scan(scan_data):
        """Save a scan to the history file"""
        history = ScanHistory.load_history()
        scan_data["scan_id"] = str(uuid.uuid4())[:8]
        history.insert(0, scan_data)

        # Keep only last 50 scans
        if len(history) > 50:
            history = history[:50]

        with open("scan_history.json", "w") as f:
            json.dump(history, f, indent=2)

        # Also save as current report
        with open("security_report.json", "w") as f:
            json.dump(scan_data, f, indent=2)

        return scan_data

    @staticmethod
    def get_scan_by_id(scan_id):
        """Get a specific scan by ID"""
        history = ScanHistory.load_history()
        return next((s for s in history if s.get("scan_id") == scan_id), None)


class SecurityScanner:
    @staticmethod
    def run_scan(
        host,
        port,
        username,
        password=None,
        target_name="Custom Target",
        ssh_key_path=None,
    ):
        """Run security scan on a specific target"""
        all_findings = []

        try:
            # Network Scanner (runs first, doesn't need SSH)
            print(f"Starting network scan of {host}...")
            network_scanner = NetworkScanner(
                host, int(port), username, password, ssh_key_path
            )
            network_results = network_scanner.scan()
            all_findings.extend(network_results)

            # SSH Scanner
            print(f"Starting SSH configuration scan...")
            ssh_scanner = SSHScanner(host, int(port), username, password, ssh_key_path)
            ssh_results = ssh_scanner.scan()
            all_findings.extend(ssh_results)

            # System Scanner
            print(f"Starting system configuration scan...")
            sys_scanner = SystemScanner(
                host, int(port), username, password, ssh_key_path
            )
            sys_results = sys_scanner.scan()
            all_findings.extend(sys_results)

        except Exception as e:
            all_findings.append(
                Finding("ERROR", "Connection", f"Failed to connect: {str(e)}")
            )

        # Create scan report
        scan_report = {
            "scan_target": f"{target_name} ({host}:{port})",
            "host": host,
            "port": port,
            "target_name": target_name,
            "total_findings": len(all_findings),
            "findings": [f.to_dict() for f in all_findings],
            "scan_time": datetime.now().isoformat(),
            "scan_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }

        return ScanHistory.save_scan(scan_report)
