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
FAIL_UNDER=""
REAL_USER=${SUDO_USER:-$USER}

run_as_user() {
    local func="$1"
    local tmpfile
    tmpfile=$(mktemp)

    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" bash -c "
            source utils/output.sh
            source checks/permissions.sh
            source checks/practices.sh
            $func
        " > "$tmpfile" 2>/dev/null
    else
        $func > "$tmpfile" 2>/dev/null
    fi

    process_results < "$tmpfile"
    rm -f "$tmpfile"
}

process_results(){
    local total_score=0
    local total_checks=0

    while IFS="|" read -r status message fix; do
        if [[ "$OUTPUT_FORMAT" == "plain" ]]; then
            case $status in
                OK) print_ok "$message" ;;
                WARN) 
                    print_warn "$message" "$fix"
                    total_score=$((total_score + 1))
                    ;;
                FAIL) 
                    print_fail "$message" "$fix"
                    total_score=$((total_score + 2))
                    ;;
            esac
        else
            # JSON mode
            if [ "$FIRST_ENTRY" = false ]; then
                JSON_OUTPUT+=","
            fi
            
            JSON_OUTPUT+="{\"status\":\"$status\",\"message\":\"$message\",\"fix\":\"$fix\"}"
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

run_audit() {
    if [[ "$OUTPUT_FORMAT" == "plain" ]]; then
        echo "=== System Audit ==="
    fi

    [[ "$OUTPUT_FORMAT" == "plain" ]] && echo "---- SSH Audit ----"
    process_results < <(audit_ssh)
    [[ "$OUTPUT_FORMAT" == "plain" ]] && echo "---- Firewall Audit ----"
    process_results < <(audit_firewall)
    [[ "$OUTPUT_FORMAT" == "plain" ]] && echo "---- Permissions Audit ----"
    run_as_user audit_permissions 
    [[ "$OUTPUT_FORMAT" == "plain" ]] && echo "---- Bad Practices ----"
    run_as_user audit_practices 

    # Score calculation
    if [ "$GLOBAL_CHECKS" -gt 0 ]; then
        local max_score=$((GLOBAL_CHECKS * 2))
        local final_score=$((100 - (GLOBAL_SCORE * 100 / max_score)))
    else
        local final_score=0
    fi

    # ---- OUTPUT ----
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        JSON_OUTPUT+="],\"score\":$final_score}"
        echo "$JSON_OUTPUT"
    else
        echo "=== Final Score ==="
        echo "Security score: $final_score / 100"

        if [ "$final_score" -ge 80 ]; then
            print_ok "System is fairly secure"
        elif [ "$final_score" -ge 60 ]; then
            print_warn "System has security weaknesses"
        else
            print_fail "System is insecure"
        fi
    fi

    # ---- FAIL-UNDER ----
    if [ -n "$FAIL_UNDER" ]; then
        if [ "$final_score" -lt "$FAIL_UNDER" ]; then
            if [[ "$OUTPUT_FORMAT" == "plain" ]]; then
                print_fail "Score below threshold ($final_score < $FAIL_UNDER)"
            fi
            exit 1
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
        --fail-under=*)
            FAIL_UNDER="${arg#*=}"
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 --audit [--json] [--fail-under=N]"
            exit 1
            ;;
    esac
done

if [ "$RUN_AUDIT" = true ]; then
    run_audit
else
    echo "usage : $0 --audit [--json]"
fi