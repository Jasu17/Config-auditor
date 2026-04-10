#!/bin/bash

audit_ssh(){
    local config="/etc/ssh/sshd_config"

    echo "--- ssh Audit ---"

    if grep -q "^PermitRootLogin no" "$config";then
        print_ok "Root login disabled"
    else
        print_fail "Root login enabled"
    fi

    if grep -q "^PasswordAuthentication no" "$config";then
        print_ok "Password authentication disabled"
    else
        print_warn "Password authentication enabled"
    fi

    if grep -q "^Port 22"; then
        print_warn "Using default SSH port"
    else
        print_ok "Non-default SSH port"
    fi
}