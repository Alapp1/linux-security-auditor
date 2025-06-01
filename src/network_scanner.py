import socket
import threading

from scanner_base import Finding, SecurityScanner


class NetworkScanner(SecurityScanner):
    def __init__(self, host, port, username, password=None, private_key_path=None):
        self.host = host
        self.port = port  # This is the SSH port we're connecting to
        self.username = username
        self.password = password
        self.private_key_path = private_key_path
        self.ssh = None

    def scan_port(self, port, timeout=3):
        """Check if a specific port is open"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((self.host, port))
            sock.close()
            return result == 0
        except:
            return False

    def scan_multiple_ports(self, ports, max_threads=50):
        """Scan multiple ports using threading for speed"""
        open_ports = []
        threads = []

        def check_port(port):
            if self.scan_port(port):
                open_ports.append(port)

        for port in ports:
            thread = threading.Thread(target=check_port, args=(port,))
            threads.append(thread)
            thread.start()

            if len(threads) >= max_threads:
                for t in threads:
                    t.join()
                threads = []

        for thread in threads:
            thread.join()

        return sorted(open_ports)

    def identify_service(self, port):
        """Identify common services running on ports"""
        common_ports = {
            21: "FTP",
            22: "SSH",
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            143: "IMAP",
            443: "HTTPS",
            993: "IMAPS",
            995: "POP3S",
            3306: "MySQL",
            5432: "PostgreSQL",
            6379: "Redis",
            27017: "MongoDB",
            3389: "RDP",
            5985: "WinRM",
            5986: "WinRM-HTTPS",
        }

        if port != 22 and port == self.port:
            return f"SSH (non-standard port {port})"

        return common_ports.get(port, f"Unknown service on port {port}")

    def scan(self):
        findings = []

        # Define ports to scan
        critical_ports = [21, 23, 135, 139, 445, 1433, 1521, 3389, 5432, 3306]
        common_ports = [22, 25, 53, 80, 110, 143, 443, 993, 995, 8080, 8443]
        high_ports = [6379, 27017, 5985, 5986, 9200, 11211]

        # Always include the SSH port we're connecting to
        all_ports = critical_ports + common_ports + high_ports
        if self.port not in all_ports:
            all_ports.append(self.port)

        try:
            print(f"Scanning {len(all_ports)} ports on {self.host}...")
            open_ports = self.scan_multiple_ports(all_ports)

            # Filter out expected/secure ports to focus on real issues
            security_issues = []

            for port in open_ports:
                service = self.identify_service(port)

                # Only report ACTUAL security problems, not normal secure services
                if port == 23:  # Telnet - CRITICAL
                    security_issues.append(
                        Finding(
                            "CRITICAL",
                            "Network",
                            f"Telnet service running on port {port}",
                            "Disable Telnet and use SSH instead",
                            {"CIS": "2.1.1", "NIST": "SC-8"},
                        )
                    )
                elif port in [135, 139, 445]:  # Windows file sharing
                    security_issues.append(
                        Finding(
                            "HIGH",
                            "Network",
                            f"Windows file sharing port {port} open ({service})",
                            "Restrict access or disable if not needed",
                            {"CIS": "2.2.1", "NIST": "AC-4"},
                        )
                    )
                elif port == 21:  # FTP
                    security_issues.append(
                        Finding(
                            "HIGH",
                            "Network",
                            f"FTP service running on port {port}",
                            "Use SFTP instead of FTP for secure file transfer",
                            {"CIS": "2.1.2", "NIST": "SC-8"},
                        )
                    )
                elif port == 3389:  # RDP
                    security_issues.append(
                        Finding(
                            "MEDIUM",
                            "Network",
                            f"RDP service running on port {port}",
                            "Ensure RDP is properly secured with NLA and strong authentication",
                            {"CIS": "2.2.2", "NIST": "AC-17"},
                        )
                    )
                elif port in [3306, 5432, 1433, 1521]:  # Databases
                    security_issues.append(
                        Finding(
                            "HIGH",
                            "Network",
                            f"Database service exposed on port {port} ({service})",
                            "Database should not be directly accessible from external networks",
                            {"CIS": "2.2.3", "NIST": "AC-4"},
                        )
                    )
                elif port == 6379:  # Redis
                    security_issues.append(
                        Finding(
                            "HIGH",
                            "Network",
                            f"Redis service on port {port} - often unsecured by default",
                            "Configure Redis authentication and bind to localhost only",
                            {"OWASP": "A6", "NIST": "AC-3"},
                        )
                    )
                elif port == 27017:  # MongoDB
                    security_issues.append(
                        Finding(
                            "HIGH",
                            "Network",
                            f"MongoDB service on port {port}",
                            "Ensure MongoDB has authentication enabled and proper access controls",
                            {"OWASP": "A6", "NIST": "AC-3"},
                        )
                    )
                # SSH on standard port 22 is an informational finding
                elif port == 22:
                    security_issues.append(
                        Finding(
                            "LOW",
                            "Network",
                            f"SSH service detected on standard port {port}",
                            "Consider moving SSH to a non-standard port for additional security",
                        )
                    )
                # DON'T report SSH on non-standard ports as findings - that's good security!
                elif port == self.port and port != 22:
                    # This is expected - SSH on non-standard port is good practice
                    pass
                else:
                    # Unknown services might be worth investigating
                    security_issues.append(
                        Finding(
                            "LOW",
                            "Network",
                            f"Unknown service detected: {service} on port {port}",
                            "Review if this service is necessary and properly secured",
                        )
                    )

            # If we found actual security issues, report them
            if security_issues:
                findings.extend(security_issues)
            else:
                # Only report this if no ports at all were found open
                if not open_ports:
                    findings.append(
                        Finding(
                            "LOW",
                            "Network",
                            "No services detected on common ports",
                            "This indicates good port security - only necessary services should be exposed",
                        )
                    )
                # If only SSH on non-standard port is open, that's actually GOOD
                elif (
                    len(open_ports) == 1 and self.port in open_ports and self.port != 22
                ):
                    findings.append(
                        Finding(
                            "LOW",
                            "Network",
                            f"Only SSH detected on non-standard port {self.port}",
                            "Good security practice - minimal attack surface with SSH on non-standard port",
                        )
                    )

        except Exception as e:
            findings.append(
                Finding("ERROR", "Network", f"Network scan failed: {str(e)}")
            )

        return findings
