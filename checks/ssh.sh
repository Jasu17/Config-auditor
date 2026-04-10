#!/bin/bash

audit_ssh(){
    local config="/etc/ssh/sshd_config"
    local results=()

    echo "--- ssh Audit ---"

    if grep -q "^PermitRootLogin no" "$config";then
        results+=("OK|Root login disabled")
    else
        results+=("FAIL|Root login enabled")
    fi

    if grep -q "^PasswordAuthentication no" "$config";then
        results+=("OK|Password authentication disabled")
    else
        results+=("WARN|Password authentication enabled")
    fi

    if grep -q "^Port 22" "$config"; then
        results+=("WARN|Using default SSH port")
    else
        results+=("OK|Non-default SSH port")
    fi


}