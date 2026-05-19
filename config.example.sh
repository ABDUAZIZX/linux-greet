# linux-greet configuration
# Copy to: ~/.config/linux-greet/config.sh
#
# Format: KEY=VALUE  (one per line, # for comments)
# Parser is whitelist-based — unknown keys are silently ignored.

# ── Sections to display (1=show, 0=hide) ────────────────────
SHOW_BANNER=1
SHOW_WELCOME=1
SHOW_DATE=1
SHOW_UPTIME=1
SHOW_GPU=1
SHOW_LOAD=1
SHOW_MEMORY=1

# ── Language: ar | en | both ────────────────────────────────
LANG_MODE=both

# ── Banner colour: red | cyan | yellow | green ──────────────
BANNER_COLOR=red

# ── Custom user greeting (overrides $USER if set) ───────────
# GREETING_NAME=
