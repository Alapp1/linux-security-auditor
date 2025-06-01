import json
import os
from abc import ABC, abstractmethod
from datetime import datetime

import paramiko


class SecurityScanner(ABC):
    def __init__(self, host, port, username, password=None, private_key_path=None):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.private_key_path = private_key_path
        self.ssh = None

    def connect(self):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        if self.private_key_path:
            # SSH key authentication
            if os.path.exists(self.private_key_path):
                try:
                    key = paramiko.RSAKey.from_private_key_file(self.private_key_path)
                except:
                    try:
                        key = paramiko.Ed25519Key.from_private_key_file(
                            self.private_key_path
                        )
                    except:
                        key = paramiko.ECDSAKey.from_private_key_file(
                            self.private_key_path
                        )

                self.ssh.connect(
                    self.host, port=self.port, username=self.username, pkey=key
                )
            else:
                raise Exception(f"Private key file not found: {self.private_key_path}")
        else:
            # Password authentication
            self.ssh.connect(
                self.host,
                port=self.port,
                username=self.username,
                password=self.password,
            )

    def disconnect(self):
        if self.ssh:
            self.ssh.close()

    def execute_command(self, command):
        stdin, stdout, stderr = self.ssh.exec_command(command)
        return stdout.read().decode(), stderr.read().decode()

    @abstractmethod
    def scan(self):
        pass


class Finding:
    def __init__(self, level, category, issue, recommendation="", compliance=None):
        self.level = level  # CRITICAL, HIGH, MEDIUM, LOW
        self.category = category  # SSH, System, Network, etc.
        self.issue = issue
        self.recommendation = recommendation
        self.timestamp = datetime.now().isoformat()
        self.compliance = compliance or {}  # {"CIS": "5.2.1", "NIST": "AC-3"}

    def to_dict(self):
        return {
            "level": self.level,
            "category": self.category,
            "issue": self.issue,
            "recommendation": self.recommendation,
            "timestamp": self.timestamp,
            "compliance": self.compliance,
        }
