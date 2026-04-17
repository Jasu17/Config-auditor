#!/bin/bash

#import checks
source checks/ssh.sh
source checks/firewall.sh
source checks/permissions.sh
source checks/practices.sh

source utils/output.sh

process_results(){
    while IFS="|" read -r status message; do
        case $status in
            OK) print_ok "$message" ;;
            WARN) print_warn "$message" ;;
            FAIL) print_fail "$message" ;;
        esac
    done
}

run_audit(){
    echo "=== System Audit ==="

    echo "---- SSH Audit ----"
    audit_ssh | process_results
    echo "---- Firewall Audit ----"
    audit_firewall | process_results
    echo "---- Permissions Audit ----"
    audit_permissions | process_results
    echo "---- Bad Practices ----"
    audit_practices | process_results
}

#CLI
if [[ "$1" == "--audit" ]]; then
    run_audit
else
    echo "Usage: $0 --audit"
fi