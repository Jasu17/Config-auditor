#!/bin/bash

audit_practices(){
    local results=()

    # --- Users without password ---
    local empty_pass
    empty_pass=$(awk -F: '($2=="") {print $1}' /etc/shadow 2>dev/null)

    if [ -n "$empty_pass" ]; then
        results+=("FAIL|Users without password detected")
    else
        results+=("OK|No users without password")
    fi

    # --- Uncommon shells --- 
    local invalid_shells
    invalid_shells=$(awk -F '($7!~/(bash|sh|zsh|nologin|false)$/){print $1}' /etc/passwd)

    if [ -n "$invalid_shells" ]; then
        results+=("WARN|Users tirh uncommon shells detected")
    else
        results+=("OK|User shells loook standard")
    fi
    
    # --- Insecure PATH ---
    if echo "$PATH" | grep -q "::"; then
        results+=("WARN|Empty entry in PATH detected")
    else
        results+=("OK|PATH structure looks clean")
    fi

    if echo "$PATH" | grep -qe "(^|:)\.(\:|$)"; then
        results+=("FAIL|Current directory in PATH (.) detected")
    else
        results+=("OK|No unsafe PATH entries")
    fi

    # --- .ssh permissions ---
    local ssh_issues
    ssh_issues=$(find /home -type d -name ".ssh" -perm -0002 2>dev/null)

    if [ -n "$ssh_issues" ]; then
        results+=("FAIL|Insecure permissions in .ssh directories")
    else
        results+=("OK|.ssh directories are secure")
    fi

    # --- Rooth PATH sanity ----
    local root_path
    root_path=$(grep "^root:" /etc/passwd | cut -d: -f7)

    if [ -z "$root_path" ]; then
        results+=("WARN|Root shell not properly defined")
    else
        results+=("OK|Root shell configured")
    fi

    printf "%s\n" "${results[@]}"
}