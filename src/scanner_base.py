from abc import ABC, abstractmethod
import paramiko
import json
from datetime import datetime

class SecurityScanner(ABC):
    def __init__(self, host, port, username, password):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.ssh = None
    
    def connect(self):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(self.host, port=self.port, username=self.username, password=self.password)
    
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
    def __init__(self, level, category, issue, recommendation=""):
        self.level = level  # CRITICAL, HIGH, MEDIUM, LOW
        self.category = category  # SSH, System, Network, etc.
        self.issue = issue
        self.recommendation = recommendation
        self.timestamp = datetime.now().isoformat()
    
    def to_dict(self):
        return {
            "level": self.level,
            "category": self.category,
            "issue": self.issue,
            "recommendation": self.recommendation,
            "timestamp": self.timestamp
        }
