#!/bin/bash

source utils/output.sh
#import checks
source checks/ssh.sh
source checks/firewall.sh
source checks/permissions.sh
source checks/practices.sh

GLOBAL_SCORE=0
GLOBAL_CHECKS=0
JSON_OUTPUT="{\"results\":["
FIRST_ENTRY=true

process_results(){
    local total_score=0
    local total_checks=0

    while IFS="|" read -r status message; do
        if [[ "$OUTPUT_FORMAT" == "plain" ]]; then
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
        else
            # JSON mode
            if [ "$FIRST_ENTRY" = false ]; then
                JSON_OUTPUT+=","
            fi
            
            JSON_OUTPUT+="{\"status\":\"$status\",\"message\":\"$message\"}"
            FIRST_ENTRY=false
            
            case $status in
                WARN) total_score=$((total_score + 1)) ;;
                FAIL) total_score=$((total_score + 2)) ;;
            esac
        fi 

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

    if [ "$OUTPUT_FORMAT" == "json" ]; then
        local max_score=$((GLOBAL_CHECKS * 2))
        local final_score=$((100 - (GLOBAL_SCORE * 100 / max_score)))

        JSON_OUTPUT+="],\"final_score\":$final_score}"
        echo "$JSON_OUTPUT"

    else
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
    fi
}

OUTPUT_FORMAT="plain"
RUN_AUDIT=false
#CLI

for arg in "$@"; do
    case $arg in
        --json)
            OUTPUT_FORMAT="json"
            ;;
        --audit)
            RUN_AUDIT=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--json] [--audit]"
            exit 1
            ;;
    esac
done

if [ "$RUN_AUDIT" = true ]; then
    run_audit
else
    echo "usage : $0 --audit [--json]"
fi