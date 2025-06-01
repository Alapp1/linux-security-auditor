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
                        {"CIS": "5.2.1", "NIST": "AC-3"},
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
                        {"CIS": "5.2.2", "NIST": "IA-2"},
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
                        {"CIS": "5.2.3", "NIST": "IA-5"},
                    )
                )

            # Check for weak ciphers
            weak_ciphers = ["3des-cbc", "aes128-cbc", "aes192-cbc", "aes256-cbc"]
            for line in config.split("\n"):
                if line.strip().startswith("Ciphers"):
                    for cipher in weak_ciphers:
                        if cipher in line:
                            findings.append(
                                Finding(
                                    "MEDIUM",
                                    "SSH",
                                    f"Weak cipher {cipher} enabled",
                                    "Remove weak ciphers from SSH configuration",
                                    {"CIS": "5.2.11"},
                                )
                            )

            self.disconnect()

        except Exception as e:
            findings.append(Finding("ERROR", "SSH", f"Scan failed: {str(e)}"))

        return findings
