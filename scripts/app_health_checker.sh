#!/bin/bash

# Application Health Checker Script
# Checks if an application is UP or DOWN based on HTTP status codes

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="app_health.log"

# Function to print usage
usage() {
    echo "Usage: $0 <URL> [OPTIONS]"
    echo "Options:"
    echo "  -t, --timeout <seconds>    Timeout for the request (default: 5)"
    echo "  -i, --interval <seconds>   Continuous monitoring interval"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Example: $0 http://localhost:4499"
    echo "         $0 http://example.com -i 10"
}

# Function to check application health
check_health() {
    local url=$1
    local timeout=${2:-5}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Make HTTP request and get status code
    http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time "$timeout" --connect-timeout 5 -N "$url" 2>/dev/null)
    curl_exit_code=$?
    
    # Check if curl command was successful
    if [ $curl_exit_code -ne 0 ]; then
        echo -e "${RED}[$timestamp] DOWN${NC} - $url - Connection failed (curl error: $curl_exit_code)" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check HTTP status code
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}[$timestamp] UP${NC} - $url - Status: $http_code" | tee -a "$LOG_FILE"
        return 0
    elif [ "$http_code" -ge 300 ] && [ "$http_code" -lt 400 ]; then
        echo -e "${YELLOW}[$timestamp] REDIRECT${NC} - $url - Status: $http_code" | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${RED}[$timestamp] DOWN${NC} - $url - Status: $http_code" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main script execution
main() {
    local url=""
    local timeout=5
    local interval=0
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -i|--interval)
                interval="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                if [ -z "$url" ]; then
                    url="$1"
                else
                    echo "Error: Unknown option $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if URL is provided
    if [ -z "$url" ]; then
        echo "Error: URL is required"
        usage
        exit 1
    fi
    
    echo "Application Health Checker"
    echo "=========================="
    echo "Monitoring: $url"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Continuous monitoring or single check
    if [ "$interval" -gt 0 ]; then
        echo "Continuous monitoring enabled (interval: ${interval}s)"
        echo "Press Ctrl+C to stop"
        echo ""
        while true; do
            check_health "$url" "$timeout"
            sleep "$interval"
        done
    else
        check_health "$url" "$timeout"
    fi
}

# Run main function
main "$@"
