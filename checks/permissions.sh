#!/bin/bash

audit_permissions(){
    local results=()

    # --- World-writable directories ---
    local ww_dirs
    ww_dirs=$(find / -xdev -type d -perm -002 2>/dev/null | head -n 5)

    if [ -n "$ww_dirs" ]; then
        results+=("WARN|world-witable directories detected")
    else
        results+=("OK|No world-writable directories found")
    fi

    # --- SUID files ---
    local suid_count
    suid_count=$(find / -xdev -perm -4000 2>dev/null | wc -l)

    if [ "$suid_count" -gt 0 ]; then
        results+=("WARN|SUID files present ($suid_count found)")
    else
        results+=("OK|No SUID files found")
    fi

    # --- /etc/passwd permissions ---
    if [ -w /etc/passwd ]; then
        results+=("FAIL|/etc/passwd is writable")
    else
        results+=("OK|/etc/passwd permissions are secure")
    fi

    # --- /etc/shadow permissions ---
    if [ -r /etc/shadow ]; then
        results+=("FAIL|/etc/shadow is readable")
    else
        results+=("OK|/etc/shadow is protected")
    fi

    # --- Home directories ---
    local insecure_home
    insecure_home=$(find /home -maxdeph 1 -type d -perm -0002 2>dev/null)

    if [ -n "$insecure_home" ]; then
        results+=("WARN|Insecure permissions in home directories")
    else
        results+=("OK|Home directory permissions look secure")
    fi

    printf "%s\n" "${results[@]}"
}