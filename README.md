# 🔒 Secure User & Log Management System

A comprehensive security tool that combines automated user management with advanced log analysis capabilities. This Bash-based system helps system administrators maintain security by detecting failed login attempts, managing user accounts with strong password policies, and generating detailed security reports.

## 📋 Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [File Structure](#file-structure)
- [Logging & Reporting](#logging--reporting)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [FAQ](#faq)
- [License](#license)

## ✨ Features

### Core Features
- **🔐 Secure FTP Server**: Automatic setup of vsftpd with TLS/SSL encryption
- **📊 Failed Login Detection**: Scans `/var/log/auth.log` for unauthorized access attempts
- **📈 Daily Reports**: Generates comprehensive HTML and text reports
- **👥 User Management**: Complete user lifecycle management (create, delete, update)
- **🔑 Password Policy Enforcement**: Enforces strong password requirements
- **📝 Action Logging**: All actions logged to `/var/log/user_mgmt.log`

### Enhanced Features
- **🤖 Automated Monitoring**: Real-time monitoring with automatic responses
- **🚫 Interactive User Selection**: Menu-driven user selection for all operations
- **💾 Backup System**: Automatic backup before user deletion
- **🔍 Security Anomaly Detection**: Identifies suspicious patterns and brute force attacks
- **📧 Email Notifications**: Sends alerts for critical security events

## 🖥️ Requirements

### System Requirements
- **OS**: Linux (Ubuntu/Debian/RHEL/CentOS)
- **RAM**: Minimum 512MB
- **Disk Space**: 100MB for logs and backups
- **Permissions**: Root or sudo access

### Dependencies
The script automatically installs required packages:
- `vsftpd` - FTP server
- `openssl` - SSL/TLS certificates
- `util-linux` - User management utilities
- `logrotate` - Log rotation

## 📥 Installation

### Method 1: Direct Download
```bash
# Download the script
wget https://your-server.com/security_system.sh

# Make executable
chmod +x security_system.sh

# Run as root
sudo ./security_system.sh