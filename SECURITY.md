# Security Notes — linux-greet

## Threat model

linux-greet is a banner script with **no privileged access**:

- Runs as the invoking user (never via sudo/root)
- Reads local files only (no network I/O)
- Writes only to user-owned cache directories
- Output goes to the user's own terminal

The realistic threat surface is therefore narrow: a local attacker who can
plant files in the user's $HOME or tamper with /etc/os-release already
has more direct paths to compromise. The defensive patterns below exist to
keep the script honest under those edge cases, not because the script
handles high-value secrets.

## Defensive measures

### Config parser (_load_config)

- **Whitelist-based**: only keys in $_ALLOWED_KEYS are accepted; unknown
  keys are silently ignored. The file is never passed to source or eval.
- **Key format validation**: keys must match ^[A-Z_][A-Z0-9_]*$ — blocks
  shell metacharacters in key names.
- **Ownership check via descriptor**: file opened first, then stat /dev/fd/$fd
  checks the open inode's owner. Closes the TOCTOU window (CWE-362) between
  a path-based stat and a subsequent read.
- **Control-character stripping**: all values pass through _strip_ctrl,
  removing \x01-\x08, \x0b-\x1f, and \x7f. Defends against terminal
  escape injection (CWE-150) from a tampered config.

### External command output

Output from nvidia-smi, ollama, /etc/os-release, and apt list is
treated as untrusted:

- Numeric fields validated via _is_int before arithmetic
- String fields pass through _strip_ctrl
- Argument injection blocked via -- separator where applicable
  (e.g. last -n 3 -F -- "$USER")

### systemctl scoping

systemctl --system is-active is used explicitly. Without --system,
systemctl checks user units first — a local attacker could create a user
unit named ufw.service returning active to mask a disabled
system-wide firewall.

### Cache writes

Security update counts are cached in $XDG_CACHE_HOME/linux-greet/:

- Atomic write via mktemp + rename(2) — concurrent readers cannot
  observe a half-written file
- Non-absolute XDG_CACHE_HOME is rejected
- Updates fetched in a detached, disowned subshell — the foreground
  banner never blocks on apt list (~400ms cold)

## Reviewed and rejected

These were considered and rejected after analysis:

- **Path traversal to /etc/passwd**: script only reads from well-known
  paths and never writes outside the user's own directories.
- **Symlink race in mktemp**: mktemp uses O_EXCL | O_CREAT — no
  usable race window.
- **Repository metadata injection via apt**: apt-secure(8) enforces
  GPG signatures on Release files; out of scope for a read-only consumer.

## Reporting

Open a GitHub issue or contact the maintainer via the repo. External
review is welcome.
