#!/bin/bash

# Automated Backup Solution
# Backs up a directory to local or remote location with logging

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_LOG="backup.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
MAX_BACKUPS=5  # Keep last 5 backups

# Function to print usage
usage() {
    echo "Usage: $0 -s <source_dir> -d <destination> [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -s, --source <dir>         Source directory to backup"
    echo "  -d, --destination <path>   Destination path (local or remote)"
    echo ""
    echo "Options:"
    echo "  -r, --remote <user@host>   Remote server for backup (uses SCP)"
    echo "  -n, --name <name>          Backup name prefix (default: backup)"
    echo "  -k, --keep <number>        Number of backups to keep (default: 5)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  Local:  $0 -s /var/www -d /backup"
    echo "  Remote: $0 -s /var/www -d /backup -r user@remote-server"
}

# Function to log messages
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$BACKUP_LOG"
}

# Function to cleanup old backups
cleanup_old_backups() {
    local backup_dir=$1
    local prefix=$2
    local keep=$3
    
    log_message "INFO" "Cleaning up old backups, keeping last $keep"
    
    # Count backup files
    backup_count=$(ls -1 "$backup_dir"/${prefix}_*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$keep" ]; then
        # Remove oldest backups
        ls -1t "$backup_dir"/${prefix}_*.tar.gz | tail -n +$((keep + 1)) | while read old_backup; do
            rm -f "$old_backup"
            log_message "INFO" "Removed old backup: $(basename $old_backup)"
        done
    fi
}

# Function to create local backup
backup_local() {
    local source=$1
    local dest_dir=$2
    local backup_name=$3
    
    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"
    
    # Backup file path
    local backup_file="$dest_dir/${backup_name}_${TIMESTAMP}.tar.gz"
    
    log_message "INFO" "Starting backup of $source"
    log_message "INFO" "Destination: $backup_file"
    
    # Create compressed backup
    if tar -czf "$backup_file" -C "$(dirname $source)" "$(basename $source)" 2>/dev/null; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_message "SUCCESS" "Backup completed successfully"
        log_message "INFO" "Backup size: $size"
        echo -e "${GREEN}✓ Backup successful: $backup_file${NC}"
        
        # Cleanup old backups
        cleanup_old_backups "$dest_dir" "$backup_name" "$MAX_BACKUPS"
        return 0
    else
        log_message "ERROR" "Backup failed"
        echo -e "${RED}✗ Backup failed${NC}"
        return 1
    fi
}

# Function to create remote backup
backup_remote() {
    local source=$1
    local dest_dir=$2
    local remote=$3
    local backup_name=$4
    
    # Create temporary local backup first
    local temp_dir="/tmp/backup_temp_$$"
    mkdir -p "$temp_dir"
    
    local backup_file="${backup_name}_${TIMESTAMP}.tar.gz"
    local temp_backup="$temp_dir/$backup_file"
    
    log_message "INFO" "Creating temporary backup"
    
    # Create compressed backup
    if tar -czf "$temp_backup" -C "$(dirname $source)" "$(basename $source)" 2>/dev/null; then
        local size=$(du -h "$temp_backup" | cut -f1)
        log_message "INFO" "Temporary backup created, size: $size"
        
        # Transfer to remote server
        log_message "INFO" "Transferring to remote server: $remote"
        
        if scp "$temp_backup" "$remote:$dest_dir/" 2>/dev/null; then
            log_message "SUCCESS" "Remote backup completed successfully"
            echo -e "${GREEN}✓ Remote backup successful${NC}"
            
            # Cleanup temp file
            rm -rf "$temp_dir"
            return 0
        else
            log_message "ERROR" "Remote transfer failed"
            echo -e "${RED}✗ Remote transfer failed${NC}"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_message "ERROR" "Backup creation failed"
        echo -e "${RED}✗ Backup creation failed${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Main script
main() {
    local source_dir=""
    local dest_path=""
    local remote_server=""
    local backup_name="backup"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                source_dir="$2"
                shift 2
                ;;
            -d|--destination)
                dest_path="$2"
                shift 2
                ;;
            -r|--remote)
                remote_server="$2"
                shift 2
                ;;
            -n|--name)
                backup_name="$2"
                shift 2
                ;;
            -k|--keep)
                MAX_BACKUPS="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate inputs
    if [ -z "$source_dir" ] || [ -z "$dest_path" ]; then
        echo "Error: Source and destination are required"
        usage
        exit 1
    fi
    
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory does not exist: $source_dir"
        exit 1
    fi
    
    # Display configuration
    echo "Automated Backup Solution"
    echo "========================="
    echo "Source:      $source_dir"
    echo "Destination: $dest_path"
    if [ -n "$remote_server" ]; then
        echo "Remote:      $remote_server"
    fi
    echo "Backup name: $backup_name"
    echo "Log file:    $BACKUP_LOG"
    echo ""
    
    # Perform backup
    if [ -n "$remote_server" ]; then
        backup_remote "$source_dir" "$dest_path" "$remote_server" "$backup_name"
    else
        backup_local "$source_dir" "$dest_path" "$backup_name"
    fi
    
    exit $?
}

# Run main
main "$@"
