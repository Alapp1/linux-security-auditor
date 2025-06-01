import json
from datetime import datetime

from ssh_scanner_v2 import SSHScanner
from system_scanner import SystemScanner


def run_security_audit(host, port, username, password):
    print(f"Starting security audit of {host}:{port}")
    print("=" * 50)

    all_findings = []

    # Run SSH scanner
    print("Scanning SSH configuration...")
    ssh_scanner = SSHScanner(host, port, username, password)
    ssh_results = ssh_scanner.scan()
    all_findings.extend(ssh_results)

    # Run System scanner
    print("Scanning system configuration...")
    sys_scanner = SystemScanner(host, port, username, password)
    sys_results = sys_scanner.scan()
    all_findings.extend(sys_results)

    # Display results
    print(f"\nSECURITY AUDIT COMPLETE")
    print(f"Total findings: {len(all_findings)}")
    print("=" * 50)

    # Group by severity
    critical = [f for f in all_findings if f.level == "CRITICAL"]
    high = [f for f in all_findings if f.level == "HIGH"]
    medium = [f for f in all_findings if f.level == "MEDIUM"]

    if critical:
        print(f"\nCRITICAL ISSUES ({len(critical)}):")
        for finding in critical:
            print(f"  • {finding.issue}")
            print(f"    → {finding.recommendation}")

    if high:
        print(f"\nHIGH PRIORITY ({len(high)}):")
        for finding in high:
            print(f"  • {finding.issue}")
            print(f"    → {finding.recommendation}")

    if medium:
        print(f"\nMEDIUM PRIORITY ({len(medium)}):")
        for finding in medium:
            print(f"  • {finding.issue}")

    # Save full report
    report = {
        "scan_target": f"{host}:{port}",
        "total_findings": len(all_findings),
        "findings": [f.to_dict() for f in all_findings],
    }

    with open("security_report.json", "w") as f:
        json.dump(report, f, indent=2)

    print(f"\nFull report saved to security_report.json")


if __name__ == "__main__":
    run_security_audit("localhost", 2222, "root", "password")
