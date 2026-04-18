#!/bin/bash

audit_ssh() {
    local config="/etc/ssh/sshd_config"
    local results=()

    # validate config file exists
    if [ ! -f "$config" ]; then
        results+=("FAIL|sshd_config not found")
        printf "%s\n" "${results[@]}"
        return
    fi

    # clean_config whitout comments and empty lines
    local clean_config
    clean_config=$(grep -vE '^\s*#' "$config" | sed '/^\s*$/d')

    # ---- Root login ----
    if echo "$clean_config" | grep -qi "PermitRootLogin no"; then
        results+=("OK|Root login disabled")
    elif echo "$clean_config" | grep -qi "PermitRootLogin prohibit-password"; then
        results+=("WARN|Root login allowed with key only")
    else
        results+=("FAIL|Root login enabled")
    fi

    # ---- Password auth ----
    if echo "$clean_config" | grep -qi "PasswordAuthentication no"; then
        results+=("OK|Password authentication disabled")
    else
        results+=("WARN|Password authentication enabled")
    fi

    # ---- SSH Port ----
    local port
    port=$(echo "$clean_config" | grep -i "^Port" | awk '{print $2}' | head -n1)

    if [ -z "$port" ]; then
        port=22
    fi

    if [ "$port" -eq 22 ]; then
        results+=("WARN|Using default SSH port (22)")
    else
        results+=("OK|Non-default SSH port ($port)")
    fi

    printf "%s\n" "${results[@]}"
}