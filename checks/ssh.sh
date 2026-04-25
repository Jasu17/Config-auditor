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

    # clean_config whitout comments and empty lines, normalize whitespace
    local clean_config
    clean_config=$(grep -vE '^\s*#' "$config" | sed '/^\s*$/d' | sed 's/[[:space:]]\+/ /g')
    
    # helper: get normalized value for a directive
    get_val(){
        echo "$clean_config" | grep -i "^$1" | awk '{print $2}' | head -n1
    }
    

    # ---- Root login ----
    local root_login
    root_login=$(get_val "PermitRootLogin")
    if [[ "${root_login,,}" == "no" ]]; then
        results+=("OK|Root login disabled")
    elif [[ "${root_login,,}" == "prohibit-password" ]]; then
        results+=("WARN|Root login allowed with key only")
    else
        results+=("FAIL|Root login enabled")
    fi

    # ---- Password auth ----
    local pwd_auth
    pwd_auth=$(get_val "PasswordAuthentication")
    if [[ "${pwd_auth,,}" == "no" ]]; then
        results+=("OK|Password authentication disabled")
    else
        results+=("WARN|Password authentication enabled")
    fi

    # ---- SSH Port ----
    local port
    port=$(get_val "Port")
    if [[ -z "$port" || ! "$port" =~ ^[0-9]+$ ]]; then
        port=22
    fi

    if [ "$port" -eq 22 ]; then
        results+=("WARN|Using default SSH port (22)")
    else
        results+=("OK|Non-default SSH port ($port)")
    fi

    # --- MaxAuthTries ---
    local max_auth
    max_auth=$(get_val "MaxAuthTries")
    if [[ -z "$max_auth" || "$max_auth" -gt 3 ]]; then
        resukts+=("WARN|MaxAuthTries not restricted (value: ${max_auth:-default})")
    else
        results+=("OK|MaxAuthTries restricted (value: $max_auth)")
    fi

    # --- X11Forwarding ---
    local x11
    x11=$(get_val "X11Forwarding")
    [[ "${x11,,}" == "yes" ]] \
        && results+=("WARN|X11 forwarding enabled") \
        || results+=("OK|X11 forwarding disabled")

    # --- AllowTcpForwarding ---
    local tcp_fwd
    tcp_fwd=$(get_val "AllowTcpForwarding")
    [[ "${tcp_fwd,,}" == "yes" ]] \
        && results+=("WARN|TCP forwarding enabled") \
        || results+=("OK|TCP forwarding disabled")

    printf "%s\n" "${results[@]}"
}