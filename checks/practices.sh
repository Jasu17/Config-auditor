#!/bin/bash

audit_practices() {
    local results=()

    # ---- Usuarios sin contraseña ----
    local empty_pass
    empty_pass=$(awk -F: '($2=="") {print $1}' /etc/shadow 2>/dev/null)

    if [ -n "$empty_pass" ]; then
        results+=("FAIL|Users without password detected|Run: passwd <user> to set a password")
    else
        results+=("OK|No users without password|")
    fi

    # ---- Shells sospechosos ----
    local invalid_shells
    invalid_shells=$(awk -F: '($7!~/\/(bash|sh|zsh|fish|dash|nologin|false|sync)$/){print $1}' /etc/passwd)

    if [ -n "$invalid_shells" ]; then
        results+=("WARN|Users with uncommon shells detected|Review /etc/passwd and set valid shells with: chsh -s /bin/bash <user>")
    else
        results+=("OK|User shells look standard|")
    fi

    # ---- PATH estructura ----
    if echo "$PATH" | grep -q "::"; then
        results+=("WARN|Empty entry in PATH detected|Check your shell profile for double colons in PATH")
    else
        results+=("OK|PATH structure looks clean|")
    fi

    # ---- PATH inseguro (.) ----
    if echo "$PATH" | grep -qE '(^|:)\.(:|$)'; then
        results+=("FAIL|Current directory in PATH detected|Remove '.' from PATH in ~/.bashrc or /etc/environment")
    else
        results+=("OK|No unsafe PATH entries|")
    fi

    # ---- .ssh permissions ----
    if [ -d /home ]; then
        local ssh_issues
        ssh_issues=$(find /home -type d -name ".ssh" -perm -0002 2>/dev/null)

        if [ -n "$ssh_issues" ]; then
            results+=("FAIL|Insecure permissions in .ssh directories|Run: chmod 700 /home/<user>/.ssh")
        else
            results+=("OK|.ssh directories are secure|")
        fi
    fi

    # ---- Root shell ----
    local root_shell
    root_shell=$(awk -F: '$1=="root"{print $7}' /etc/passwd)

    if [ -z "$root_shell" ]; then
        results+=("WARN|Root shell not properly defined|Set a valid shell for root in /etc/passwd")
    else
        results+=("OK|Root shell configured|")
    fi

    printf "%s\n" "${results[@]}"
}