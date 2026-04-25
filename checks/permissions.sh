#!/bin/bash

audit_permissions() {
    local results=()

    # ---- World-writable directories ----
    local ww_dirs
    ww_dirs=$(find / -xdev -type d -perm -0002 2>/dev/null | head -n 5)

    if [ -n "$ww_dirs" ]; then
        results+=("WARN|World-writable directories detected|Run: chmod o-w <dir> on affected directories")
    else
        results+=("OK|No world-writable directories found|")
    fi

    # ---- SUID files ----
    local suid_count
    suid_count=$(find / -xdev -perm -4000 2>/dev/null | wc -l)

    if [ "$suid_count" -gt 50 ]; then
        results+=("WARN|High number of SUID files ($suid_count)|Review with: find / -perm -4000 and remove unnecessary SUID bits")
    else
        results+=("OK|SUID file count looks normal ($suid_count)|")
    fi

    # ---- /etc/passwd ----
    if [ -w /etc/passwd ]; then
        results+=("FAIL|/etc/passwd is writable|Run: chmod 644 /etc/passwd")
    else
        results+=("OK|/etc/passwd permissions are secure|")
    fi

    # ---- /etc/shadow ----
    if [ -r /etc/shadow ]; then
        results+=("FAIL|/etc/shadow is readable|Run: chmod 640 /etc/shadow")
    else
        results+=("OK|/etc/shadow is protected|")
    fi

    # ---- Home directories ----
    if [ -d /home ]; then
        local insecure_home
        insecure_home=$(find /home -maxdepth 1 -type d -perm -0002 2>/dev/null)

        if [ -n "$insecure_home" ]; then
            results+=("WARN|Insecure permissions in home directories|Run: chmod o-w /home/<user>")
        else
            results+=("OK|Home directory permissions look secure|")
        fi
    fi

    printf "%s\n" "${results[@]}"
}