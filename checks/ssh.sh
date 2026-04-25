#!/bin/bash

audit_ssh() {
    local config="/etc/ssh/sshd_config"
    local results=()

    if [ ! -f "$config" ]; then
        results+=("FAIL|sshd_config not found|Install openssh-server or check /etc/ssh/")
        printf "%s\n" "${results[@]}"
        return
    fi

    local clean_config
    clean_config=$(grep -vE '^\s*#' "$config" | sed '/^\s*$/d' | sed 's/[[:space:]]\+/ /g')

    get_val() {
        echo "$clean_config" | grep -i "^$1 " | awk '{print $2}' | head -n1
    }

    # ---- Root login ----
    local root_login
    root_login=$(get_val "PermitRootLogin")
    if [[ "${root_login,,}" == "no" ]]; then
        results+=("OK|Root login disabled|")
    elif [[ "${root_login,,}" == "prohibit-password" ]]; then
        results+=("WARN|Root login allowed with key only|Set PermitRootLogin no in sshd_config")
    else
        results+=("FAIL|Root login enabled|Set PermitRootLogin no in sshd_config")
    fi

    # ---- Password auth ----
    local pwd_auth
    pwd_auth=$(get_val "PasswordAuthentication")
    if [[ "${pwd_auth,,}" == "no" ]]; then
        results+=("OK|Password authentication disabled|")
    else
        results+=("WARN|Password authentication enabled|Set PasswordAuthentication no in sshd_config")
    fi

    # ---- SSH Port ----
    local port
    port=$(get_val "Port")
    if [[ -z "$port" || ! "$port" =~ ^[0-9]+$ ]]; then
        port=22
    fi
    if [ "$port" -eq 22 ]; then
        results+=("WARN|Using default SSH port (22)|Change Port to a non-standard value in sshd_config")
    else
        results+=("OK|Non-default SSH port ($port)|")
    fi

    # ---- MaxAuthTries ----
    local max_auth
    max_auth=$(get_val "MaxAuthTries")
    if [[ -z "$max_auth" || "$max_auth" -gt 3 ]]; then
        results+=("WARN|MaxAuthTries not restricted (value: ${max_auth:-default})|Set MaxAuthTries 3 in sshd_config")
    else
        results+=("OK|MaxAuthTries is restricted ($max_auth)|")
    fi

    # ---- X11Forwarding ----
    local x11
    x11=$(get_val "X11Forwarding")
    [[ "${x11,,}" == "yes" ]] \
        && results+=("WARN|X11Forwarding is enabled|Set X11Forwarding no in sshd_config") \
        || results+=("OK|X11Forwarding is disabled|")

    # ---- AllowTcpForwarding ----
    local tcp_fwd
    tcp_fwd=$(get_val "AllowTcpForwarding")
    [[ "${tcp_fwd,,}" == "yes" ]] \
        && results+=("WARN|AllowTcpForwarding is enabled|Set AllowTcpForwarding no in sshd_config") \
        || results+=("OK|AllowTcpForwarding is disabled|")

    printf "%s\n" "${results[@]}"
}