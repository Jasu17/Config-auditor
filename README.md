# Config Auditor

A Bash tool to audit Linux system security configurations. Evaluates SSH hardening, firewall rules, file permissions and system practices, then assigns a security score from 0 to 100.

## Requirements

- Bash 4+
- Root or sudo access (required for firewall and shadow checks)
- `ufw` or `iptables` for firewall auditing

## Usage

```bash
sudo bash auditor.sh --audit
```

### Flags

| Flag | Description |
|------|-------------|
| `--audit` | Run the full audit |
| `--json` | Output results as JSON instead of plain text |
| `--fail-under=N` | Exit with code 1 if score is below N (useful for CI/CD) |

## Output modes

### Plain

```bash
sudo bash auditor.sh --audit
```

```
=== System Audit ===
---- SSH Audit ----
[OK] Root login disabled
[WARN] Password authentication enabled
       → Fix: Set PasswordAuthentication no in sshd_config
[FAIL] Root login enabled
       → Fix: Set PermitRootLogin no in sshd_config
...
=== Final Score ===
Security score: 55 / 100
[FAIL] System is insecure
```

### JSON

```bash
sudo bash auditor.sh --audit --json
```

```json
{
  "results": [
    { "status": "OK",   "message": "Root login disabled",               "fix": "" },
    { "status": "WARN", "message": "Password authentication enabled",   "fix": "Set PasswordAuthentication no in sshd_config" },
    { "status": "FAIL", "message": "No firewall tool detected",         "fix": "Install ufw: apt install ufw && ufw enable" }
  ],
  "score": 55
}
```

### CI/CD enforcement

```bash
sudo bash auditor.sh --audit --fail-under=70
```

Exits with code `1` if the score is below the threshold. Combine with `--json` for machine-readable output in pipelines.

## Checks performed

### SSH (`/etc/ssh/sshd_config`)
- Root login disabled
- Password authentication disabled
- Non-default port
- MaxAuthTries restricted
- X11Forwarding disabled
- AllowTcpForwarding disabled

### Firewall
- UFW or iptables active
- Default incoming policy is deny
- SSH port exposure
- Permissive ACCEPT rules

### Permissions
- World-writable directories
- SUID file count
- `/etc/passwd` and `/etc/shadow` permissions
- Home directory permissions

### System practices
- Users without passwords
- Uncommon login shells
- Unsafe PATH entries
- `.ssh` directory permissions
- Root shell defined

## Scoring

Each check returns `OK`, `WARN` or `FAIL`:

| Result | Penalty |
|--------|---------|
| OK     | 0       |
| WARN   | 1       |
| FAIL   | 2       |

Final score: `100 - (total_penalty * 100 / max_possible_penalty)`

A score of 80+ is considered secure. Below 60 is flagged as insecure.

## Project structure

```
.
├── auditor.sh
├── checks/
│   ├── ssh.sh
│   ├── firewall.sh
│   ├── permissions.sh
│   └── practices.sh
└── utils/
    └── output.sh
```

## License

MIT
