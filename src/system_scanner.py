from scanner_base import Finding, SecurityScanner


class SystemScanner(SecurityScanner):
    def scan(self):
        findings = []

        try:
            self.connect()

            # Check shadow file permissions
            shadow_perms, _ = self.execute_command("ls -la /etc/shadow")
            if not shadow_perms.startswith("-rw-r-----"):
                findings.append(
                    Finding(
                        "HIGH",
                        "System",
                        "Insecure /etc/shadow permissions",
                        "Run: chmod 640 /etc/shadow",
                        {"CIS": "6.1.3", "NIST": "AC-3"},
                    )
                )

            # Check for users with empty passwords
            empty_pass, _ = self.execute_command(
                "awk -F: '($2 == \"\") {print $1}' /etc/shadow"
            )
            if empty_pass.strip():
                findings.append(
                    Finding(
                        "CRITICAL",
                        "System",
                        f"Users with empty passwords: {empty_pass.strip()}",
                        "Set passwords for all users",
                        {"CIS": "5.4.1.1", "NIST": "IA-5"},
                    )
                )

            # Check world-writable files
            world_write, _ = self.execute_command(
                "find /etc -type f -perm -002 2>/dev/null"
            )
            if world_write.strip():
                findings.append(
                    Finding(
                        "MEDIUM",
                        "System",
                        "World-writable files found in /etc",
                        "Review and fix file permissions",
                        {"CIS": "6.1.10", "NIST": "AC-3"},
                    )
                )

            self.disconnect()

        except Exception as e:
            findings.append(Finding("ERROR", "System", f"Scan failed: {str(e)}"))

        return findings
