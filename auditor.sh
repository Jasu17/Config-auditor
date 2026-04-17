#!/bin/bash

source utils/output.sh
#import checks
source checks/ssh.sh
source checks/firewall.sh
source checks/permissions.sh
source checks/practices.sh

GLOBAL_SCORE=0
GLOBAL_CHECKS=0

process_results(){
    local total_score=0
    local total_checks=0

    while IFS="|" read -r status message; do
        case $status in
            OK) print_ok "$message" ;;
            WARN) 
                print_warn "$message" 
                total_score=$((total_score + 1))
                ;;
            FAIL) 
                print_fail "$message" 
                total_score=$((total_score + 2))
                ;;
        esac

        total_checks=$((total_checks +1))
    done

    GLOBAL_SCORE=$((GLOBAL_SCORE + total_score))
    GLOBAL_CHECKS=$((GLOBAL_CHECKS + total_checks))
}

run_audit(){
    echo "=== System Audit ==="

    echo "---- SSH Audit ----"
    process_results < <(audit_ssh)
    echo "---- Firewall Audit ----"
    process_results < <(audit_firewall)
    echo "---- Permissions Audit ----"
    process_results < <(audit_permissions)
    echo "---- Bad Practices ----"
    process_results < <(audit_practices)

    echo "=== Final Score ==="
    if [ "$GLOBAL_CHECKS" -gt 0 ]; then
        local max_score=$((GLOBAL_CHECKS * 2))
        local final_score=$((100 - (GLOBAL_SCORE * 100 / max_score)))

        echo "Security score: $final_score / 100"
    
        if [ "$final_score" -ge 80 ]; then
            print_ok "System is fairly secure"
        elif [ "$final_score" -ge 60 ]; then
            print_warn "System has security weaknesses"
        else
            print_fail "System is insecure"

        fi
    fi
}

#CLI
if [[ "$1" == "--audit" ]]; then
    run_audit
else
    echo "Usage: $0 --audit"
fi