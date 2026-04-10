#!/bin/bash

#import utils
source utils/output.sh

#import checks
source checks/ssh.sh
source checks/firewall.sh
source checks/permissions.sh
source checks/practices.sh

run_audit(){
    echo "=== System Audit ==="

    audit_ssh
    audit_firewall
    audit_permissions
    audit_practices
}

#CLI
if [[ "$1" == "--audit" ]]; then
    run_audit
else
    echo "Usage: $0 --audit"
fi