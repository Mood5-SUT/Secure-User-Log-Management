#!/bin/bash

# ============================================================================
# Secure User & Log Management System
# Author: System Security Tool
# Description: Dual-function tool for log analysis and user management
# ============================================================================

# Configuration
AUTH_LOG="/var/log/auth.log"
USER_MGMT_LOG="/var/log/user_mgmt.log"
REPORT_DIR="/var/log/security_reports"
FAILED_LOGIN_THRESHOLD=5
SECURE_FTP_PORT=2121
SECURE_FTP_ROOT="/var/secure_ftp"
MAX_FAILED_ATTEMPTS=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Initialization Functions
# ============================================================================

initialize_system() {
    echo -e "${GREEN}[+] Initializing Secure User & Log Management System...${NC}"
    
    # Create necessary directories
    mkdir -p "$REPORT_DIR"
    mkdir -p "$SECURE_FTP_ROOT"
    
    # Create log files if they don't exist
    touch "$USER_MGMT_LOG"
    touch "$AUTH_LOG" 2>/dev/null || echo -e "${YELLOW}[!] Warning: Cannot access $AUTH_LOG${NC}"
    
    # Set proper permissions
    chmod 755 "$REPORT_DIR"
    chmod 644 "$USER_MGMT_LOG"
    
    # Initialize log rotation if needed
    if [ ! -f "/etc/logrotate.d/user_mgmt" ]; then
        echo "$USER_MGMT_LOG {
    daily
    rotate 30
    compress
    missingok
    notifempty
}" | sudo tee /etc/logrotate.d/user_mgmt > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}[+] System initialized successfully${NC}"
}

log_action() {
    local action="$1"
    local user="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] ACTION: $action | USER: $user | DETAILS: $details" >> "$USER_MGMT_LOG"
    echo -e "${GREEN}[LOG] $action - $user - $details${NC}"
}

# ============================================================================
# Password Policy Enforcement
# ============================================================================

validate_password_strength() {
    local password="$1"
    local username="$2"
    
    # Password policy checks
    if [ ${#password} -lt 12 ]; then
        echo "Password must be at least 12 characters long"
        return 1
    fi
    
    if ! [[ "$password" =~ [A-Z] ]]; then
        echo "Password must contain at least one uppercase letter"
        return 1
    fi
    
    if ! [[ "$password" =~ [a-z] ]]; then
        echo "Password must contain at least one lowercase letter"
        return 1
    fi
    
    if ! [[ "$password" =~ [0-9] ]]; then
        echo "Password must contain at least one number"
        return 1
    fi
    
    if ! [[ "$password" =~ [\!@#\$%^\&*()_+] ]]; then
        echo "Password must contain at least one special character (!@#$%^&*()_+)"
        return 1
    fi
    
    if [[ "$password" =~ "$username" ]]; then
        echo "Password cannot contain username"
        return 1
    fi
    
    # Check against common passwords
    local common_passwords=("password123" "admin123" "12345678" "qwerty123" "letmein123" "Password123!" "Admin@123")
    for common in "${common_passwords[@]}"; do
        if [[ "$password" == "$common" ]]; then
            echo "Password is too common. Please choose a stronger password"
            return 1
        fi
    done
    
    return 0
}

generate_secure_password() {
    # Generate a random secure password
    local password=$(openssl rand -base64 16 2>/dev/null | tr -d "=+/" | cut -c1-16)
    echo "$password"
}

set_password_policies() {
    echo -e "${GREEN}[+] Enforcing system-wide password policies...${NC}"
    
    # Configure password expiration policies
    if [ -f "/etc/login.defs" ]; then
        sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
        sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
        sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
    fi
    
    # Configure PAM for password strength
    if [ -f "/etc/pam.d/common-password" ]; then
        sudo apt-get install -y libpam-pwquality 2>/dev/null || yum install -y pam_pwquality 2>/dev/null
    fi
    
    log_action "PASSWORD_POLICY_UPDATE" "SYSTEM" "Global password policies enforced"
}

# ============================================================================
# User Management Functions
# ============================================================================

create_user() {
    local username="$1"
    local password="$2"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}[!] User $username already exists${NC}"
        log_action "CREATE_USER_FAILED" "$username" "User already exists"
        return 1
    fi
    
    # Validate username
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo -e "${RED}[!] Invalid username format${NC}"
        log_action "CREATE_USER_FAILED" "$username" "Invalid username format"
        return 1
    fi
    
    # If no password provided, generate one
    if [ -z "$password" ]; then
        password=$(generate_secure_password)
        echo -e "${YELLOW}[!] Generated password for $username: $password${NC}"
    else
        # Validate password strength
        if ! validate_password_strength "$password" "$username"; then
            echo -e "${RED}[!] Password policy validation failed${NC}"
            log_action "CREATE_USER_FAILED" "$username" "Password policy validation failed"
            return 1
        fi
    fi
    
    # Create user with home directory
    sudo useradd -m -s /bin/bash "$username"
    if [ $? -eq 0 ]; then
        echo "$username:$password" | sudo chpasswd
        
        # Force password change on first login
        sudo chage -d 0 "$username"
        
        # Set user quota and limits
        echo "$username soft nproc 100" | sudo tee -a /etc/security/limits.conf
        echo "$username hard nproc 150" | sudo tee -a /etc/security/limits.conf
        
        # Add to appropriate groups
        sudo usermod -aG "$username" "$username"
        
        echo -e "${GREEN}[+] User $username created successfully${NC}"
        log_action "CREATE_USER" "$username" "User created with password policy enforced"
        
        # Create secure FTP directory for user
        mkdir -p "$SECURE_FTP_ROOT/$username"
        sudo chown "$username:$username" "$SECURE_FTP_ROOT/$username"
        chmod 700 "$SECURE_FTP_ROOT/$username"
        
        return 0
    else
        echo -e "${RED}[!] Failed to create user $username${NC}"
        log_action "CREATE_USER_FAILED" "$username" "System error"
        return 1
    fi
}

# Enhanced Delete User Function with Selection Menu
delete_user() {
    local username="$1"
    
    # If username not provided as argument, show selection menu
    if [ -z "$username" ]; then
        echo -e "${YELLOW}[!] Loading user list...${NC}"
        echo ""
        
        # Get list of regular users
        local users=()
        while IFS= read -r user; do
            users+=("$user")
        done < <(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)
        
        # Check if there are any users to delete
        if [ ${#users[@]} -eq 0 ]; then
            echo -e "${RED}[!] No regular users found on the system${NC}"
            log_action "DELETE_USER_FAILED" "SYSTEM" "No regular users available for deletion"
            return 1
        fi
        
        # Display users in a nice table
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                           SELECT USER TO DELETE                           ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        printf "%-5s %-20s %-8s %-30s %-15s\n" "No." "USERNAME" "UID" "HOME DIRECTORY" "SHELL"
        echo "----------------------------------------------------------------------------------------"
        
        local count=1
        for user in "${users[@]}"; do
            local uid=$(id -u "$user" 2>/dev/null)
            local shell=$(getent passwd "$user" | cut -d: -f7)
            local home=$(getent passwd "$user" | cut -d: -f6)
            
            # Color code based on user activity (check if user has processes)
            local user_processes=$(pgrep -u "$user" 2>/dev/null | wc -l)
            if [ "$user_processes" -gt 0 ]; then
                printf "${YELLOW}%-5s %-20s %-8s %-30s %-15s (Active: %d processes)${NC}\n" "$count." "$user" "$uid" "$home" "$shell" "$user_processes"
            else
                printf "%-5s %-20s %-8s %-30s %-15s\n" "$count." "$user" "$uid" "$home" "$shell"
            fi
            ((count++))
        done
        
        echo "----------------------------------------------------------------------------------------"
        echo -e "${YELLOW}0. Cancel / Go Back${NC}"
        echo ""
        
        # Get user selection
        while true; do
            echo -n "Select user number to delete [1-${#users[@]}] or 0 to cancel: "
            read -r selection
            
            # Validate input
            if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}[!] Invalid input. Please enter a number.${NC}"
                continue
            fi
            
            if [ "$selection" -eq 0 ]; then
                echo -e "${GREEN}[+] Operation cancelled${NC}"
                log_action "DELETE_USER_CANCELLED" "SYSTEM" "User deletion cancelled by admin"
                return 0
            fi
            
            if [ "$selection" -ge 1 ] && [ "$selection" -le ${#users[@]} ]; then
                username="${users[$((selection-1))]}"
                break
            else
                echo -e "${RED}[!] Invalid selection. Please choose a number between 0 and ${#users[@]}${NC}"
            fi
        done
    fi
    
    # Don't allow deletion of system users (additional safety)
    local system_users=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd" "dbus")
    for sysuser in "${system_users[@]}"; do
        if [[ "$username" == "$sysuser" ]]; then
            echo -e "${RED}[!] Cannot delete system user: $username${NC}"
            log_action "DELETE_USER_FAILED" "$username" "Attempted to delete system user"
            return 1
        fi
    done
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}[!] User $username does not exist${NC}"
        log_action "DELETE_USER_FAILED" "$username" "User does not exist"
        return 1
    fi
    
    # Show user information before deletion
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    USER INFORMATION                           ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    local uid=$(id -u "$username")
    local gid=$(id -g "$username")
    local home=$(getent passwd "$username" | cut -d: -f6)
    local shell=$(getent passwd "$username" | cut -d: -f7)
    local groups=$(groups "$username" 2>/dev/null | cut -d: -f2)
    local last_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{print $4,$5,$6,$7,$8,$9}')
    local user_processes=$(pgrep -u "$username" 2>/dev/null | wc -l)
    
    echo -e "${CYAN}Username:       $username${NC}"
    echo -e "${CYAN}UID:            $uid${NC}"
    echo -e "${CYAN}GID:            $gid${NC}"
    echo -e "${CYAN}Home Directory: $home${NC}"
    echo -e "${CYAN}Shell:          $shell${NC}"
    echo -e "${CYAN}Groups:        $groups${NC}"
    echo -e "${CYAN}Last Login:     ${last_login:-Never}${NC}"
    echo -e "${CYAN}Active Processes: $user_processes${NC}"
    
    # Check for user files and data
    local user_files=$(find /home -user "$username" 2>/dev/null | wc -l)
    echo -e "${CYAN}Files owned:    $user_files${NC}"
    
    echo ""
    
    # Confirm deletion
    echo -e "${RED}⚠️  WARNING: This action is irreversible! ⚠️${NC}"
    echo "This will:"
    echo "  • Remove user account: $username"
    echo "  • Delete home directory: $home"
    echo "  • Remove mail spool: /var/mail/$username"
    echo "  • Remove all files owned by user (found: $user_files files)"
    echo "  • Remove user from all groups"
    echo ""
    
    while true; do
        echo -n "Are you absolutely sure you want to delete user '$username'? (yes/no/backup): "
        read -r confirm
        
        case "$confirm" in
            yes|YES|y|Y)
                # Create backup before deletion
                local backup_dir="/var/backups/users/$username"
                mkdir -p "$backup_dir"
                
                echo -e "${YELLOW}[+] Creating backup of user data...${NC}"
                sudo tar -czf "$backup_dir/${username}_$(date +%Y%m%d_%H%M%S).tar.gz" "$home" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}[+] Backup created: $backup_dir/${username}_$(date +%Y%m%d_%H%M%S).tar.gz${NC}"
                else
                    echo -e "${YELLOW}[!] Warning: Could not create backup (home directory may not exist)${NC}"
                fi
                
                # Kill user processes if any
                if [ "$user_processes" -gt 0 ]; then
                    echo -e "${YELLOW}[+] Terminating user processes...${NC}"
                    pkill -u "$username" 2>/dev/null
                    sleep 1
                fi
                
                # Remove user and home directory
                sudo userdel -r "$username" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}[+] User $username deleted successfully${NC}"
                    echo -e "${GREEN}[+] Backup saved to: $backup_dir${NC}"
                    log_action "DELETE_USER" "$username" "User deleted with backup at $backup_dir"
                    
                    # Remove FTP directory if exists
                    rm -rf "$SECURE_FTP_ROOT/$username" 2>/dev/null
                    
                    # Remove from sudoers if present
                    sudo rm -f "/etc/sudoers.d/$username" 2>/dev/null
                    
                    return 0
                else
                    echo -e "${RED}[!] Failed to delete user $username${NC}"
                    log_action "DELETE_USER_FAILED" "$username" "System error during deletion"
                    return 1
                fi
                ;;
            
            backup|BACKUP|b|B)
                # Create backup only, don't delete
                backup_dir="/var/backups/users/$username"
                mkdir -p "$backup_dir"
                sudo tar -czf "$backup_dir/${username}_$(date +%Y%m%d_%H%M%S).tar.gz" "$home" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}[+] Backup created at: $backup_dir/${username}_$(date +%Y%m%d_%H%M%S).tar.gz${NC}"
                    echo -e "${GREEN}[+] User $username was NOT deleted${NC}"
                    log_action "BACKUP_ONLY" "$username" "Backup created without deletion"
                else
                    echo -e "${RED}[!] Backup failed${NC}"
                fi
                return 0
                ;;
            
            no|NO|n|N)
                echo -e "${GREEN}[+] Deletion cancelled for user $username${NC}"
                log_action "DELETE_USER_CANCELLED" "$username" "User cancelled deletion"
                return 0
                ;;
            
            *)
                echo -e "${RED}[!] Please answer 'yes', 'no', or 'backup'${NC}"
                ;;
        esac
    done
}

update_user() {
    local username="$1"
    local new_password="$2"
    
    # Show user selection if username not provided
    if [ -z "$username" ]; then
        echo -e "${YELLOW}[!] Loading user list...${NC}"
        echo ""
        
        # Get list of regular users
        local users=()
        while IFS= read -r user; do
            users+=("$user")
        done < <(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)
        
        if [ ${#users[@]} -eq 0 ]; then
            echo -e "${RED}[!] No regular users found on the system${NC}"
            return 1
        fi
        
        # Display users
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    SELECT USER TO UPDATE                   ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        printf "%-5s %-20s %-8s %-30s\n" "No." "USERNAME" "UID" "HOME DIRECTORY"
        echo "----------------------------------------------------------------"
        
        local count=1
        for user in "${users[@]}"; do
            local uid=$(id -u "$user" 2>/dev/null)
            local home=$(getent passwd "$user" | cut -d: -f6)
            printf "%-5s %-20s %-8s %-30s\n" "$count." "$user" "$uid" "$home"
            ((count++))
        done
        
        echo "----------------------------------------------------------------"
        echo -e "${YELLOW}0. Cancel / Go Back${NC}"
        echo ""
        
        while true; do
            echo -n "Select user number to update [1-${#users[@]}] or 0 to cancel: "
            read -r selection
            
            if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}[!] Invalid input. Please enter a number.${NC}"
                continue
            fi
            
            if [ "$selection" -eq 0 ]; then
                echo -e "${GREEN}[+] Operation cancelled${NC}"
                return 0
            fi
            
            if [ "$selection" -ge 1 ] && [ "$selection" -le ${#users[@]} ]; then
                username="${users[$((selection-1))]}"
                break
            else
                echo -e "${RED}[!] Invalid selection. Please choose a number between 0 and ${#users[@]}${NC}"
            fi
        done
    fi
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}[!] User $username does not exist${NC}"
        log_action "UPDATE_USER_FAILED" "$username" "User does not exist"
        return 1
    fi
    
    # Get new password if not provided
    if [ -z "$new_password" ]; then
        echo -n "Enter new password for $username: "
        read -r new_password
    fi
    
    # Validate new password
    if ! validate_password_strength "$new_password" "$username"; then
        echo -e "${RED}[!] Password policy validation failed${NC}"
        log_action "UPDATE_USER_FAILED" "$username" "Password policy validation failed"
        return 1
    fi
    
    # Update password
    echo "$username:$new_password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Password for user $username updated successfully${NC}"
        log_action "UPDATE_USER" "$username" "Password updated"
        return 0
    else
        echo -e "${RED}[!] Failed to update password for user $username${NC}"
        log_action "UPDATE_USER_FAILED" "$username" "System error"
        return 1
    fi
}

lock_user() {
    local username="$1"
    
    # Show user selection if username not provided
    if [ -z "$username" ]; then
        echo -e "${YELLOW}[!] Loading user list...${NC}"
        echo ""
        
        local users=()
        while IFS= read -r user; do
            users+=("$user")
        done < <(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)
        
        if [ ${#users[@]} -eq 0 ]; then
            echo -e "${RED}[!] No regular users found on the system${NC}"
            return 1
        fi
        
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                     SELECT USER TO LOCK                    ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        printf "%-5s %-20s %-8s %-15s\n" "No." "USERNAME" "UID" "STATUS"
        echo "--------------------------------------------------------"
        
        local count=1
        for user in "${users[@]}"; do
            local uid=$(id -u "$user" 2>/dev/null)
            local passwd_status=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
            printf "%-5s %-20s %-8s %-15s\n" "$count." "$user" "$uid" "$passwd_status"
            ((count++))
        done
        
        echo "--------------------------------------------------------"
        echo -e "${YELLOW}0. Cancel / Go Back${NC}"
        echo ""
        
        while true; do
            echo -n "Select user number to lock/unlock [1-${#users[@]}] or 0 to cancel: "
            read -r selection
            
            if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}[!] Invalid input. Please enter a number.${NC}"
                continue
            fi
            
            if [ "$selection" -eq 0 ]; then
                echo -e "${GREEN}[+] Operation cancelled${NC}"
                return 0
            fi
            
            if [ "$selection" -ge 1 ] && [ "$selection" -le ${#users[@]} ]; then
                username="${users[$((selection-1))]}"
                break
            else
                echo -e "${RED}[!] Invalid selection. Please choose a number between 0 and ${#users[@]}${NC}"
            fi
        done
    fi
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}[!] User $username does not exist${NC}"
        return 1
    fi
    
    # Check current status and toggle
    local current_status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
    if [ "$current_status" = "L" ]; then
        # User is locked, unlock them
        sudo passwd -u "$username"
        echo -e "${GREEN}[+] User $username unlocked${NC}"
        log_action "UNLOCK_USER" "$username" "User account unlocked"
    else
        # User is not locked, lock them
        sudo passwd -l "$username"
        echo -e "${GREEN}[+] User $username locked${NC}"
        log_action "LOCK_USER" "$username" "User account locked"
    fi
}

# ============================================================================
# Log Analysis Functions
# ============================================================================

analyze_failed_logins() {
    echo -e "${GREEN}[+] Analyzing failed login attempts...${NC}"
    
    if [ ! -f "$AUTH_LOG" ]; then
        echo -e "${RED}[!] Auth log file not found: $AUTH_LOG${NC}"
        return 1
    fi
    
    local report_file="$REPORT_DIR/failed_logins_$(date +%Y%m%d).txt"
    local summary_file="$REPORT_DIR/summary_$(date +%Y%m%d).txt"
    
    # Extract failed password entries
    echo "=== Failed Login Attempts Report ===" > "$report_file"
    echo "Date: $(date)" >> "$report_file"
    echo "===================================" >> "$report_file"
    echo "" >> "$report_file"
    
    # Count failures per IP
    echo "Failed Logins by IP Address:" >> "$report_file"
    grep "Failed password" "$AUTH_LOG" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn >> "$report_file"
    
    # Identify suspicious IPs (exceeding threshold)
    echo "" >> "$report_file"
    echo "=== Suspicious IP Addresses (${FAILED_LOGIN_THRESHOLD}+ failures) ===" >> "$report_file"
    
    local suspicious_ips=$(grep "Failed password" "$AUTH_LOG" | awk '{print $(NF-3)}' | sort | uniq -c | awk -v threshold="$FAILED_LOGIN_THRESHOLD" '$1 >= threshold {print $2}')
    
    if [ -n "$suspicious_ips" ]; then
        echo "$suspicious_ips" >> "$report_file"
        
        # Generate alert for each suspicious IP
        while IFS= read -r ip; do
            if [ -n "$ip" ]; then
                local count=$(grep "Failed password" "$AUTH_LOG" | grep "$ip" | wc -l)
                echo -e "${YELLOW}[ALERT] Suspicious activity from IP: $ip ($count failed attempts)${NC}"
                log_action "SECURITY_ALERT" "SYSTEM" "Suspicious IP: $ip with $count failed attempts"
            fi
        done <<< "$suspicious_ips"
    else
        echo "No suspicious IPs detected" >> "$report_file"
    fi
    
    # Detect brute force patterns
    echo "" >> "$report_file"
    echo "=== Brute Force Detection ===" >> "$report_file"
    
    local brute_force=$(grep "Failed password" "$AUTH_LOG" | awk '{print $1,$2,$3}' | uniq -c | awk '$1 > 10 {print}')
    if [ -n "$brute_force" ]; then
        echo "Possible brute force attacks detected:" >> "$report_file"
        echo "$brute_force" >> "$report_file"
    else
        echo "No brute force patterns detected" >> "$report_file"
    fi
    
    # Generate summary
    local total_failures=$(grep -c "Failed password" "$AUTH_LOG")
    local unique_ips=$(grep "Failed password" "$AUTH_LOG" | awk '{print $(NF-3)}' | sort -u | wc -l)
    
    {
        echo ""
        echo "=== Daily Summary ==="
        echo "Total failed attempts: $total_failures"
        echo "Unique attacking IPs: $unique_ips"
        echo "Date: $(date)"
        echo "Report generated by: Secure User Management System"
    } > "$summary_file"
    
    echo -e "${GREEN}[+] Report generated: $report_file${NC}"
    echo -e "${GREEN}[+] Summary generated: $summary_file${NC}"
    
    log_action "LOG_ANALYSIS" "SYSTEM" "Failed login analysis completed. Total failures: $total_failures"
    
    # Return suspicious IPs count
    echo "$suspicious_ips" | wc -w
}

detect_security_anomalies() {
    echo -e "${GREEN}[+] Scanning for security anomalies...${NC}"
    
    local anomaly_file="$REPORT_DIR/anomalies_$(date +%Y%m%d).txt"
    
    {
        echo "=== Security Anomalies Report ==="
        echo "Date: $(date)"
        echo "================================"
        echo ""
        
        # Check for sudo failures
        echo "1. Sudo Failures:"
        grep "sudo.*FAILED" "$AUTH_LOG" 2>/dev/null | tail -20
        echo ""
        
        # Check for user additions/removals
        echo "2. Recent User Account Changes:"
        grep -E "useradd|userdel|usermod" "$USER_MGMT_LOG" 2>/dev/null | tail -20
        echo ""
        
        # Check for invalid users
        echo "3. Invalid User Attempts:"
        grep "Invalid user" "$AUTH_LOG" 2>/dev/null | tail -20
        echo ""
        
        # Check for authentication failures from invalid users
        echo "4. Authentication Failures (Invalid Users):"
        grep "authentication failure" "$AUTH_LOG" 2>/dev/null | tail -20
        echo ""
        
        # Check for unexpected service restarts
        echo "5. Critical Service Changes:"
        grep -E "sshd.*restart|systemd.*start.*ssh" "$AUTH_LOG" 2>/dev/null | tail -10
        
    } > "$anomaly_file"
    
    echo -e "${GREEN}[+] Anomaly report generated: $anomaly_file${NC}"
    
    # Check for critical anomalies
    local critical_found=0
    
    if grep -q "Invalid user" "$AUTH_LOG" 2>/dev/null; then
        critical_found=1
        echo -e "${RED}[CRITICAL] Invalid user attempts detected!${NC}"
    fi
    
    if grep -q "sudo.*FAILED" "$AUTH_LOG" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Failed sudo attempts detected${NC}"
    fi
    
    if [ $critical_found -eq 1 ]; then
        log_action "SECURITY_ANOMALY" "SYSTEM" "Critical anomalies detected - check $anomaly_file"
    fi
}

# ============================================================================
# Secure FTP Server Setup
# ============================================================================

setup_secure_ftp_server() {
    echo -e "${GREEN}[+] Setting up Secure FTP Server...${NC}"
    
    # Install vsftpd if not present
    if ! command -v vsftpd &> /dev/null; then
        echo -e "${YELLOW}[!] Installing vsftpd...${NC}"
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y vsftpd 2>/dev/null || sudo yum install -y vsftpd 2>/dev/null
    fi
    
    # Create vsftpd configuration
    local ftp_config="/etc/vsftpd.conf"
    sudo cp "$ftp_config" "${ftp_config}.backup" 2>/dev/null
    
    # Secure FTP configuration
    sudo tee "$ftp_config" > /dev/null << 'EOF'
# Secure vsftpd configuration
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000
max_per_ip=2
max_clients=50
idle_session_timeout=600
data_connection_timeout=120
EOF
    
    # Restart FTP service
    sudo systemctl restart vsftpd 2>/dev/null || sudo service vsftpd restart 2>/dev/null
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        sudo ufw allow 21/tcp
        sudo ufw allow 30000:31000/tcp
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=21/tcp
        sudo firewall-cmd --permanent --add-port=30000-31000/tcp
        sudo firewall-cmd --reload
    fi
    
    echo -e "${GREEN}[+] Secure FTP Server configured on port 21 (TLS/SSL enabled)${NC}"
    log_action "FTP_SETUP" "SYSTEM" "Secure FTP server configured with TLS/SSL"
}

# ============================================================================
# Automated Monitoring & Reporting
# ============================================================================

generate_daily_report() {
    echo -e "${GREEN}[+] Generating daily security report...${NC}"
    
    local daily_report="$REPORT_DIR/daily_report_$(date +%Y%m%d).html"
    
    {
        echo "<!DOCTYPE html>"
        echo "<html>"
        echo "<head><title>Daily Security Report - $(date)</title>"
        echo "<style>"
        echo "body { font-family: Arial, sans-serif; margin: 20px; }"
        echo ".header { background-color: #4CAF50; color: white; padding: 10px; }"
        echo ".warning { background-color: #ff9800; padding: 10px; }"
        echo ".critical { background-color: #f44336; color: white; padding: 10px; }"
        echo ".section { border: 1px solid #ddd; margin: 10px 0; padding: 10px; }"
        echo "</style>"
        echo "</head>"
        echo "<body>"
        
        echo "<div class='header'>"
        echo "<h1>Daily Security Report</h1>"
        echo "<p>Date: $(date)</p>"
        echo "<p>Host: $(hostname)</p>"
        echo "</div>"
        
        # Failed login summary
        echo "<div class='section'>"
        echo "<h2>Failed Login Summary</h2>"
        echo "<pre>"
        cat "$REPORT_DIR/summary_$(date +%Y%m%d).txt" 2>/dev/null
        echo "</pre>"
        echo "</div>"
        
        # Suspicious IPs
        echo "<div class='section'>"
        echo "<h2>Suspicious IP Addresses</h2>"
        echo "<pre>"
        grep -A 20 "Suspicious IP Addresses" "$REPORT_DIR/failed_logins_$(date +%Y%m%d).txt" 2>/dev/null
        echo "</pre>"
        echo "</div>"
        
        # Top attackers
        echo "<div class='section'>"
        echo "<h2>Top 10 Attackers</h2>"
        echo "<pre>"
        grep "Failed password" "$AUTH_LOG" 2>/dev/null | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10
        echo "</pre>"
        echo "</div>"
        
        # User management actions
        echo "<div class='section'>"
        echo "<h2>User Management Actions (Last 24 hours)</h2>"
        echo "<pre>"
        tail -50 "$USER_MGMT_LOG"
        echo "</pre>"
        echo "</div>"
        
        echo "</body>"
        echo "</html>"
    } > "$daily_report"
    
    echo -e "${GREEN}[+] Daily report generated: $daily_report${NC}"
    log_action "DAILY_REPORT" "SYSTEM" "Daily security report generated"
}

auto_monitor() {
    echo -e "${GREEN}[+] Starting automated monitoring...${NC}"
    
    while true; do
        analyze_failed_logins
        detect_security_anomalies
        
        # Automatically lock users with too many failed attempts
        local suspicious_users=$(grep "Failed password" "$AUTH_LOG" | awk '{print $9}' | sort | uniq -c | awk -v threshold="$MAX_FAILED_ATTEMPTS" '$1 >= threshold {print $2}')
        for user in $suspicious_users; do
            if id "$user" &>/dev/null; then
                echo -e "${RED}[AUTO-LOCK] Locking user $user due to multiple failed login attempts${NC}"
                lock_user "$user"
                log_action "AUTO_LOCK" "$user" "Automatically locked due to ${MAX_FAILED_ATTEMPTS}+ failed attempts"
            fi
        done
        
        # Wait for next scan interval (5 minutes)
        sleep 300
    done
}

# ============================================================================
# View Logs Function
# ============================================================================

view_logs() {
    echo -e "${GREEN}[+] Recent User Management Logs:${NC}"
    echo "========================================"
    tail -30 "$USER_MGMT_LOG"
    echo ""
    
    echo -e "${GREEN}[+] Recent Auth Logs (Failed Passwords):${NC}"
    echo "========================================"
    tail -20 "$AUTH_LOG" | grep "Failed password" || echo "No recent failed attempts"
    echo ""
    
    echo -e "${GREEN}[+] Current System Users:${NC}"
    echo "========================================"
    echo -e "${CYAN}Regular Users:${NC}"
    awk -F: '$3 >= 1000 && $3 < 65534 {printf "  %-20s (UID: %-5d Home: %s)\n", $1, $3, $6}' /etc/passwd | sort
    echo ""
    echo -e "${YELLOW}Total regular users: $(awk -F: '$3 >= 1000 && $3 < 65534' /etc/passwd | wc -l)${NC}"
}

# ============================================================================
# Main Menu & Interface
# ============================================================================

show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}  Secure User & Log Management System${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}1. Analyze Failed Logins${NC}"
    echo -e "${CYAN}2. Detect Security Anomalies${NC}"
    echo -e "${CYAN}3. Generate Daily Report${NC}"
    echo -e "${CYAN}4. Create New User${NC}"
    echo -e "${CYAN}5. Delete User${NC}"
    echo -e "${CYAN}6. Update User Password${NC}"
    echo -e "${CYAN}7. Lock/Unlock User${NC}"
    echo -e "${CYAN}8. Setup Secure FTP Server${NC}"
    echo -e "${CYAN}9. Start Automated Monitoring${NC}"
    echo -e "${CYAN}10. View Recent Logs${NC}"
    echo -e "${CYAN}11. Enforce Password Policies${NC}"
    echo -e "${RED}12. Exit${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -n "Select option [1-12]: "
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}[!] Please run as root or with sudo privileges${NC}"
        exit 1
    fi
    
    # Initialize system
    initialize_system
    set_password_policies
    
    # Main loop
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                analyze_failed_logins
                ;;
            2)
                detect_security_anomalies
                ;;
            3)
                generate_daily_report
                ;;
            4)
                echo -n "Enter username: "
                read -r username
                echo -n "Enter password (leave empty for auto-generate): "
                read -r password
                create_user "$username" "$password"
                ;;
            5)
                delete_user  # No argument - will show selection menu
                ;;
            6)
                update_user  # No argument - will show selection menu
                ;;
            7)
                lock_user  # No argument - will show selection menu
                ;;
            8)
                setup_secure_ftp_server
                ;;
            9)
                echo -e "${YELLOW}[!] Starting automated monitoring (press Ctrl+C to stop)...${NC}"
                auto_monitor
                ;;
            10)
                view_logs
                ;;
            11)
                set_password_policies
                ;;
            12)
                echo -e "${GREEN}[+] Exiting Secure User Management System${NC}"
                log_action "SYSTEM_EXIT" "SYSTEM" "Security system shutdown"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
        
        echo ""
        echo -n "Press Enter to continue..."
        read -r
    done
}

# Run main function
main