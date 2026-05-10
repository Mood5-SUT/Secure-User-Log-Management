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


### Method 2: Manual Setup
```bash
# Create the script file
sudo nano /usr/local/bin/security_system.sh

# Paste the script content, then:
sudo chmod +x /usr/local/bin/security_system.sh

# Run the system
sudo security_system.sh
```

### Method 3: Quick Install
```bash
# Clone from repository (if available)
git clone https://github.com/your-repo/security-system.git
cd security-system
sudo bash security_system.sh
```

## 🚀 Quick Start

### First Time Setup
1. **Run as root**:
   ```bash
   sudo bash security_system.sh
   ```

2. **Initial configuration**:
   - The system automatically initializes directories
   - Creates necessary log files
   - Sets up log rotation

3. **Setup FTP Server** (Option 8):
   - Configures vsftpd with SSL/TLS
   - Opens required firewall ports
   - Creates chroot jail for users

### Basic Workflow Example
```bash
# 1. Create a new user
Select option 4 → Enter username → Generate password

# 2. Analyze failed logins
Select option 1 → View report

# 3. Generate daily report
Select option 3 → Check HTML report

# 4. Start monitoring (optional)
Select option 9 → Real-time monitoring begins
```

## 📖 Detailed Usage

### Main Menu Options

| Option | Function | Description |
|--------|----------|-------------|
| 1 | Analyze Failed Logins | Scans auth.log, counts failures per IP, generates reports |
| 2 | Detect Security Anomalies | Identifies suspicious patterns and potential threats |
| 3 | Generate Daily Report | Creates HTML report with security statistics |
| 4 | Create New User | Interactive user creation with password policy |
| 5 | Delete User | Menu-driven user deletion with backup |
| 6 | Update User Password | Change user password with validation |
| 7 | Lock/Unlock User | Toggle user account status |
| 8 | Setup Secure FTP Server | Configure vsftpd with TLS/SSL |
| 9 | Start Automated Monitoring | Continuous security monitoring |
| 10 | View Recent Logs | Display recent user management actions |
| 11 | Enforce Password Policies | Apply system-wide password policies |
| 12 | Exit | Shutdown the system |

### Creating a User
```bash
Option 4: Create New User
→ Enter username: john_doe
→ Enter password: (leave empty for auto-generate)
→ System validates password strength
→ User created with home directory and FTP access
```

### Deleting a User
```bash
Option 5: Delete User
→ Select user from interactive menu
→ View user information
→ Confirm deletion (yes/no/backup)
→ Automatic backup created
→ User account removed
```

### Analyzing Security Logs
```bash
Option 1: Analyze Failed Logins
→ Scans /var/log/auth.log
→ Counts failures per IP address
→ Identifies brute force attempts
→ Generates detailed report
→ Auto-alerts for suspicious activity
```

## ⚙️ Configuration

### System Variables
Edit these variables at the top of the script:

```bash
# Log file locations
AUTH_LOG="/var/log/auth.log"
USER_MGMT_LOG="/var/log/user_mgmt.log"
REPORT_DIR="/var/log/security_reports"

# Security thresholds
FAILED_LOGIN_THRESHOLD=5      # Alert after 5 failures
MAX_FAILED_ATTEMPTS=3         # Lock user after 3 failures

# FTP configuration
SECURE_FTP_PORT=2121
SECURE_FTP_ROOT="/var/secure_ftp"
```

### Password Policy Configuration
The system enforces:
- **Minimum length**: 12 characters
- **Complexity**: Uppercase, lowercase, numbers, special characters
- **Password age**: 90 days maximum
- **History**: Prevents password reuse
- **Common passwords**: Blocked list included

### Customizing Password Policy
Edit the `validate_password_strength()` function:
```bash
# Change minimum length from 12 to 15
if [ ${#password} -lt 15 ]; then

# Add more common passwords to blocklist
local common_passwords+=("your_password_here")
```

## 🔒 Security Features

### Password Requirements
✅ Minimum 12 characters  
✅ At least one uppercase letter  
✅ At least one lowercase letter  
✅ At least one number  
✅ At least one special character  
✅ No username in password  
✅ No common passwords  
✅ No sequential characters  
✅ No repeated characters (4+ times)

### User Account Protection
- **Automatic locking**: After 3 failed login attempts
- **Password expiration**: Every 90 days
- **First login**: Forces password change
- **Resource limits**: CPU and file restrictions
- **Process limits**: Maximum processes per user

### FTP Security
- **TLS/SSL encryption**: All data encrypted
- **Chroot jail**: Users confined to home directory  
- **Anonymous disabled**: No anonymous access
- **Passive mode**: Restricted port range
- **Connection limits**: Max 2 connections per IP

### Monitoring & Alerts
- **Real-time scanning**: Every 5 minutes
- **IP tracking**: Monitors failed attempts per IP
- **User tracking**: Monitors failed attempts per user
- **Email alerts**: For critical events
- **Log rotation**: Prevents disk full issues

## 📁 File Structure

```
/var/log/
├── auth.log                      # System authentication log
├── user_mgmt.log                 # User management actions log
└── security_reports/             # Report directory
    ├── failed_logins_YYYYMMDD.txt
    ├── summary_YYYYMMDD.txt
    ├── anomalies_YYYYMMDD.txt
    └── daily_report_YYYYMMDD.html

/var/secure_ftp/                  # FTP user directories
├── username1/                    # User-specific FTP folder
└── username2/

/var/backups/users/               # User backup directory
├── username1/
│   └── username1_YYYYMMDD_HHMMSS.tar.gz
└── username2/

/etc/
├── vsftpd.conf                   # FTP server configuration
├── login.defs                    # Password policy settings
└── security/limits.conf          # User resource limits
```

## 📊 Logging & Reporting

### Log File Format
```
[2024-01-15 10:30:45] ACTION: CREATE_USER | USER: john_doe | DETAILS: User created
[2024-01-15 11:20:10] ACTION: DELETE_USER | USER: jane_doe | DETAILS: User deleted
[2024-01-15 12:00:00] ACTION: SECURITY_ALERT | USER: SYSTEM | DETAILS: Suspicious IP detected
```

### Report Types

#### Failed Login Report (`failed_logins_YYYYMMDD.txt`)
- Failed attempts by IP address
- Suspicious IP identification
- Brute force detection
- Daily summary statistics

#### Security Anomalies Report (`anomalies_YYYYMMDD.txt`)
- Sudo failures
- Invalid user attempts
- Authentication failures
- Service restarts

#### Daily HTML Report (`daily_report_YYYYMMDD.html`)
- Visual statistics
- Top 10 attackers
- User management summary
- System status

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Issue 1: Permission Denied
```bash
Error: Please run as root or with sudo privileges
Solution: sudo bash security_system.sh
```

#### Issue 2: Auth.log Not Found
```bash
Error: Auth log file not found: /var/log/auth.log
Solution: 
# Check if rsyslog is running
sudo systemctl status rsyslog
# Restart if needed
sudo systemctl restart rsyslog
```

#### Issue 3: FTP Server Won't Start
```bash
Error: vsftpd service failed to start
Solution:
# Check configuration syntax
sudo vsftpd -op listens=NO /etc/vsftpd.conf
# Check port availability
sudo netstat -tulpn | grep :21
# Review logs
sudo tail -f /var/log/vsftpd.log
```

#### Issue 4: Password Validation Too Strict
```bash
# Modify password requirements in validate_password_strength()
# Change minimum length from 12 to 8
if [ ${#password} -lt 8 ]; then
```

### Debug Mode
```bash
# Run with bash debug
sudo bash -x security_system.sh

# Check specific function
sudo bash -c "source security_system.sh; analyze_failed_logins"

# View real-time logs
sudo tail -f /var/log/user_mgmt.log
```

## 💡 Best Practices

### Daily Operations
1. **Morning**: Check daily reports (Option 3)
2. **During day**: Monitor failed logins (Option 1)
3. **As needed**: Review anomalies (Option 2)
4. **Weekly**: Review user accounts (Option 10)

### Security Recommendations
1. **Run as root**: Always use sudo for full functionality
2. **Regular updates**: Keep the script updated
3. **Backup rotation**: Configure automatic backup cleanup
4. **Report retention**: Keep reports for 90 days minimum
5. **Audit logs**: Regularly review `/var/log/user_mgmt.log`

### Performance Tuning
```bash
# Adjust monitoring interval (default 300 seconds)
sleep 60  # Check every minute instead of 5

# Modify auto-lock threshold
MAX_FAILED_ATTEMPTS=5  # Lock after 5 attempts

# Change report retention in logrotate config
rotate 60  # Keep 60 days of logs
```

## ❓ FAQ

**Q: Can I run this on a production server?**  
A: Yes, the script is designed for production use with proper error handling and logging.

**Q: How do I restore a deleted user?**  
A: Use the backup file in `/var/backups/users/username/`:
```bash
sudo tar -xzf backup_file.tar.gz -C /
sudo useradd -m username
```

**Q: Does this work with SELinux?**  
A: Yes, but you may need to adjust SELinux policies for FTP.

**Q: Can I integrate this with other monitoring tools?**  
A: Yes, the HTML reports and log files can be parsed by external tools.

**Q: How long are logs retained?**  
A: Logs are rotated daily and kept for 30 days by default.

**Q: What happens if disk space is full?**  
A: Log rotation prevents disk full issues. Old logs are compressed automatically.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📞 Support

For issues and questions:
- **Documentation**: Check this README first
- **Issues**: Submit on GitHub issues
- **Email**: security-admin@yourdomain.com

## 🔄 Version History

- **v1.0** (Current): Initial release with all core features
  - Secure FTP server setup
  - Failed login detection
  - User management automation
  - Password policy enforcement
  - Complete logging system

---

## 🎯 Quick Reference Card

```bash
# Start the system
sudo bash security_system.sh

# Common operations
Option 1 → Check failed logins
Option 4 → Create user
Option 5 → Delete user  
Option 8 → Setup FTP
Option 9 → Start monitoring

# Log locations
/var/log/user_mgmt.log          # User actions
/var/log/security_reports/       # Daily reports
/var/backups/users/              # User backups

# Emergency commands (run manually)
sudo tail -f /var/log/auth.log   # Monitor logins
sudo passwd -l username          # Lock user
sudo iptables -L -n              # Check bans
```

---

**⚠️ Important**: Always test in a non-production environment first. Regular backups are recommended before performing bulk user operations.

**📌 Note**: This tool requires root privileges for full functionality including log access, user management, and FTP configuration.

**🎉 Congratulations!** You're now ready to secure your system with the Secure User & Log Management System.
```
