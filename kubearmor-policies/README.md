# KubeArmor Zero-Trust Security Policy

## Policy Overview
This KubeArmor policy enforces zero-trust security for the Wisecow application.

## Security Controls

### Process Restrictions
- **Allowed processes:**
  - `/usr/games/cowsay` - Required for cow ASCII art
  - `/usr/games/fortune` - Required for fortune quotes
  - `/bin/bash` - Required for script execution
  - `/usr/bin/nc` - Required for network communication
- **Default action:** Block all other processes

### File Access Controls
- **Allowed directories:**
  - `/app/` - Application files
  - `/tmp/` - Temporary files
- **Blocked files:**
  - `/etc/passwd` - Prevents credential access
  - `/etc/shadow` - Prevents password hash access

### Network Controls
- **Allowed:** TCP connections only
- **Blocked:** UDP traffic


## Installation (for reference)
```bash
# Install KubeArmor
karmor install

# Apply policy
kubectl apply -f wisecow-security-policy.yaml

# Monitor violations
karmor logs --follow
```

## Expected Behavior
- Wisecow application runs normally
- Attempts to access `/etc/passwd` or `/etc/shadow` are blocked
- Attempts to run unauthorized processes are blocked
- Only TCP network traffic is allowed
