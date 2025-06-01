from scanner_base import Finding, SecurityScanner


class SSHScanner(SecurityScanner):
    def scan(self):
        findings = []

        try:
            self.connect()
            config, _ = self.execute_command("cat /etc/ssh/sshd_config")

            # Root login check
            if "PermitRootLogin yes" in config:
                findings.append(
                    Finding(
                        "CRITICAL",
                        "SSH",
                        "Root login is enabled",
                        "Set 'PermitRootLogin no' in /etc/ssh/sshd_config",
                    )
                )

            # Password authentication
            if "PasswordAuthentication yes" in config:
                findings.append(
                    Finding(
                        "HIGH",
                        "SSH",
                        "Password authentication enabled",
                        "Use SSH keys and set 'PasswordAuthentication no'",
                    )
                )

            # Empty passwords
            if "PermitEmptyPasswords yes" in config:
                findings.append(
                    Finding(
                        "CRITICAL",
                        "SSH",
                        "Empty passwords permitted",
                        "Set 'PermitEmptyPasswords no'",
                    )
                )

            self.disconnect()

        except Exception as e:
            findings.append(Finding("ERROR", "SSH", f"Scan failed: {str(e)}"))

        return findings
