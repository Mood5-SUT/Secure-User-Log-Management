# Secure User & Log Management System - Team Collaboration Guide

## File Ownership & Responsibilities

### Amr's Files (FTP Server)

**Member A owns these files:**

| File | Description |
|------|-------------|
| `setup_ftp.sh` | Main FTP setup script |
| `configs/vsftpd.conf.template` | FTP configuration reference |
| `scripts/ftp_user_manager.sh` | FTP whitelist management |
| `scripts/setup_ftp_user.sh` | FTP directory setup per user |
| `tests/test_ftp.sh` | FTP-specific tests |
| `monitoring/check_ftp_health.sh` | FTP service monitoring |

---

### Mohamed's Files (Log Analysis)

**Member B owns these files:**

| File | Description |
|------|-------------|
| `log_analyzer.sh` | Main log analysis script |
| `configs/crontab.template` | Cron job configuration |
| `reports/` | Generated HTML reports directory |
| `scripts/backup_logs.sh` | Log rotation script |
| `tests/test_log_analyzer.sh` | Log analyzer tests |
| `tests/fixtures/test_auth.log` | Sample log data for testing |
| `monitoring/alert_on_bruteforce.sh` | Real-time alerting |

---

### Mahmoud's Files (User Management)

**Member C owns these files:**

| File | Description |
|------|-------------|
| `user_management.sh` | Main user management script |
| `configs/pwquality.conf.template` | Password policy template |
| `configs/common-password.template` | PAM configuration template |
| `scripts/generate_ssh_keys.sh` | SSH key management |
| `tests/test_user_mgmt.sh` | User management tests |
| `tests/test_password_policy.sh` | Password strength tests |
| `monitoring/emergency_lockdown.sh` | Emergency procedures |

---

### Shared/Integration Files

**All team members collaborate on:**

| File/Directory | Description |
|----------------|-------------|
| `integration_test.sh` | End-to-end testing |
| `TEST_PLAN.md` | Testing strategy |
| `docs/` | Shared documentation |
| `logs/` | Runtime logs (all scripts write here) |
| `backups/` | Backup storage |
| `.gitignore` | Version control exclusions |

---

## Collaboration Notes

- Each member is responsible for their assigned files
- Shared files require team review before changes
- All scripts should log to the shared `logs/` directory
- Use the integration test script before final submission
