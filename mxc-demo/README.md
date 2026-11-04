# MXC PowerShell demo

Prepared November 1, 2026. Targets the stable MXC 1.0.0 request contract and the
Windows `processcontainer` backend. Requires PowerShell 7 (`pwsh.exe`), not Windows PowerShell.

Obtain the signed Windows executor and its companion files from Microsoft's release
package. Set the path below to the appropriate extracted `wxc-exec.exe`:

```powershell
$mxc = 'C:\Tools\MXC\wxc-exec.exe' # Replace with your actual location.

# Show that the SAME operations work outside the demo's MXC policy.
& "$PSHOME\pwsh.exe" `
    -NoProfile -NonInteractive -File "$PWD\Scripts\Test-MxcBoundary.ps1"

# Review/validate the request without executing the workload.
& $mxc --dry-run .\Policies\0cls0-block-demo-access.json

# Run all probes under each policy.
& $mxc .\Policies\00-block-demo-access.json
& $mxc .\Policies\01-allow-file-read.json
& $mxc .\Policies\02-allow-file-readwrite.json
& $mxc .\Policies\03-allow-tcp443-only.json
& $mxc .\Policies\04-allow-file-and-tcp443.json
```

Do not use `--audit`; it relaxes containment. Dry-run success validates startup
requirements/policy; it does not prove every workload operation will behave as expected.

## What the script attempts

The script always makes the actual calls. It contains no policy simulation.
Use `-Probe ReadFile`, `WriteFile`, `Processes`, or `Web` for a single probe in a
normal run. To select one for MXC, append `-Probe ReadFile` (for example) to the
JSON's `process.commandLine`. The default is `All`.

| Policy | Read dummy file | Append to same file | Download HTTPS page |
|---|---|---|---|
| 00-block-demo-access | Denied | Denied | Denied |
| 01-allow-file-read | Allowed | Denied | Denied |
| 02-allow-file-readwrite | Allowed | Allowed | Denied |
| 03-allow-tcp443-only | Denied | Denied | TCP 443 allowed |
| 04-allow-file-and-tcp443 | Allowed | Allowed | TCP 443 allowed |

The web probe downloads into memory so a disk-write denial cannot masquerade as
a network denial. It does not execute the response and does not follow redirects.
File writes append a harmless line to Data/demo.txt. To reset that text, edit it
outside MXC. The test prints genuine exception details and attempts all probes;
its final exit code is not a pass/fail verdict for policy enforcement.

`Get-Process` is observational under EVERY policy. There is no documented MXC JSON
permission to toggle host process enumeration. Visibility depends on the OS/backend,
and process metadata visibility is distinct from permission to control a process or
read its memory. A list may be filtered or succeed. Do not narrate it as guaranteed denied.

## Read the policy changes

Each profile is a complete independent request. Profiles 01/02 enable file access;
03 independently enables TCP 443; 04 combines both. To edit 00 manually:

- Read: remove the dummy path from `deniedPaths`, add it to `readonlyPaths`.
- Write: remove it from `deniedPaths`/`readonlyPaths`, add it to `readwritePaths`.
- TCP 443: leave `egress.default` as `deny`, add:

```json
"allow": [{ "ports": [{ "protocol": "tcp", "port": 443 }] }]
```

The allow rule intentionally omits `to`: it matches any destination IP, subject
to the backend's private-network and loopback restrictions. Port 443 does not
identify HTTPS and does not allow only example.com. It permits TCP traffic on
that port. Website/domain filtering requires a separately managed filtering proxy;
direct rules use numeric IP/CIDR, protocol, and port. Keep ingress and host loopback
denied for this public-site demo. Corporate proxies, DNS, TLS, redirects, or a site
outage can still cause failure when the policy permits traffic. Confirm the ordinary
host run succeeds first; inspect diagnostics before calling a failure a policy denial.

## What 'blocked baseline' means here

00 denies the dummy file and external network. It is NOT literally zero access:
PowerShell must read the script and its runtime, and Windows supplies a backend
baseline needed to launch processes. The policy explicitly grants those startup paths.
It grants volume-root enumeration only for startup compatibility, without file-content
read access to the whole drive. This requires native enumerate-path support.

`ui.disable` is false because disabling Win32k can prevent PowerShell from initializing.
Clipboard access and input injection remain denied. This demo is about file/network
controls; it does not claim complete UI shutdown. No full user profile or drive is
granted read/write access. Do not replace a startup problem with broad drive permissions.

Use a supported, updated Windows host. Unsupported denied-path/enumeration features
should reject startup; that is different from a script operation being denied.
PowerShell initialization can have version-specific requirements. Diagnose an early
startup error separately rather than presenting it as a successful file/network test.
