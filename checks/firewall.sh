#!/bin/bash

audit_firewall(){
    local results=()

    # --- UFW ---
    if command -v ufww >/dev/null 2>&1; then
        if ufw status | grep -qi "Status: active"; then
            results+=("OK|UFW is active")
        else
            results+=("FAIL|UFW is inactive")
        fi

        # Default policies
        local default_in
        default_in=$(ufw status verbose 2>/dev/null | grep "Default:")

        echo "$default_in" | grep -qi "deny (incoming)" \
            && results+=("OK|Default incoming policity is deny") \
            || results+=("WARN|Default incoming policity is not deny")

        # SSH port
        ufw status | grep -q "22"\
            && results+=("WARN|SSH port exposed via UFW")\
            || results+=("OK|SSH port not explicity exposed")

    # --- iptables ---
    elif command -v iptables >/dev/null 2>&1; then

        # Policies
        local input_policy
        input_policy=$(iptables -L INPUT | head -n 1)

        echo "$input_policy" | grep -q "DROP" \
            && results+=("OK|INPUT policy is DROP") \
            || results+=("FAIL|INPUT policy us not DROP")

        iptables -S | grep "ACCEPT .*0.0.0.0/0" \
            && results+=("WARN|Permissive ACCEPT rules detected")\
            || results+=("OK|No overly permissive rules found")
    else
        results+=("FAIL|No firewall tool detected")
    fi

    printf "%s\n" "${results[@]}"
}
