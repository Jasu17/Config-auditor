#!/bin/bash

audit_firewall(){
    local results=()

    # ---- Privilege check ----
    if [ "$EUID" -ne 0 ]; then
        results+=("WARN|Firewall checks require root privileges")
        printf "%s\n" "${results[@]}"
        return
    fi

    # ---- UFW ----
    if command -v ufw >/dev/null 2>&1; then

        if ufw status 2>/dev/null | grep -qi "Status: active"; then
            results+=("OK|UFW is active")
        else
            results+=("FAIL|UFW is inactive")
        fi

        local default_in
        default_in=$(ufw status verbose 2>/dev/null | grep "Default:")

        echo "$default_in" | grep -qi "deny (incoming)" \
            && results+=("OK|Default incoming policy is deny") \
            || results+=("WARN|Default incoming policy is not deny")

        ufw status 2>/dev/null | grep -q "22" \
            && results+=("WARN|SSH port exposed via UFW") \
            || results+=("OK|SSH port not explicitly exposed")

    # ---- iptables ----
    elif command -v iptables >/dev/null 2>&1; then

        local input_policy
        input_policy=$(iptables -L INPUT 2>/dev/null | head -n 1)

        echo "$input_policy" | grep -q "DROP" \
            && results+=("OK|INPUT policy is DROP") \
            || results+=("FAIL|INPUT policy is not DROP")

        iptables -S 2>/dev/null | grep -q "ACCEPT .*0.0.0.0/0" \
            && results+=("WARN|Permissive ACCEPT rules detected") \
            || results+=("OK|No overly permissive rules found")

    else
        results+=("FAIL|No firewall tool detected")
    fi

    printf "%s\n" "${results[@]}"
}