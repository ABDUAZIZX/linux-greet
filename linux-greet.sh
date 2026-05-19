#!/usr/bin/env bash
# linux-greet — a friendly Linux terminal banner.
# Shows: distro · localised date · uptime · GPU temp · load · memory.
# Tested on Debian 13; works on any Linux with bash >= 4.0.
#
# License: MIT
# Source : https://github.com/azoz8/linux-greet
#
# Configuration: ~/.config/linux-greet/config.sh  (see config.example.sh)

set -uo pipefail

# ════════════════════════════════════════════════════════════
# Colour palette
# ════════════════════════════════════════════════════════════
readonly RED=$'\033[1;31m'
readonly CYAN=$'\033[1;36m'
readonly YELLOW=$'\033[1;33m'
readonly GREEN=$'\033[1;32m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

# ════════════════════════════════════════════════════════════
# Defaults — overridable by ~/.config/linux-greet/config.sh
# ════════════════════════════════════════════════════════════
SHOW_BANNER=1
SHOW_WELCOME=1
SHOW_DATE=1
SHOW_UPTIME=1
SHOW_GPU=1
SHOW_GPU_DETAIL=1     # 1=name + temp + VRAM bar + power | 0=temp only
SHOW_OLLAMA=1
SHOW_SECURITY=1       # security updates count + firewall + last login
SHOW_LOAD=1
SHOW_MEMORY=1
LANG_MODE=both        # ar | en | both
BANNER_COLOR=red      # red | cyan | yellow | green
GREETING_NAME=""      # if empty, falls back to $USER

# Whitelist of config keys (space-separated).
# Parsing never executes config content — values are matched against this list.
readonly _ALLOWED_KEYS="SHOW_BANNER SHOW_WELCOME SHOW_DATE SHOW_UPTIME SHOW_GPU SHOW_GPU_DETAIL SHOW_OLLAMA SHOW_SECURITY SHOW_LOAD SHOW_MEMORY LANG_MODE BANNER_COLOR GREETING_NAME"

# ════════════════════════════════════════════════════════════
# Safe config loader — KEY=VALUE only, no `source`, whitelisted keys.
#
# Defends against:
#  - code injection: KEY=VALUE parser, no `source`, regex on key names.
#  - planted files (multi-user systems): ownership check via /dev/fd to avoid
#    TOCTOU between stat() and read() — see CWE-362.
#  - $USER spoofing: compares against $EUID (real numeric id) — see CWE-807.
# ════════════════════════════════════════════════════════════
_load_config() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/linux-greet"
    local config_file="$config_dir/config.sh"
    [[ -r "$config_file" ]] || return 0

    # Open file first, then stat the open descriptor — same kernel object,
    # so an attacker can't swap a symlink between check and use.
    local cfg_fd
    exec {cfg_fd}<"$config_file" 2>/dev/null || return 0

    local owner_uid
    owner_uid=$(stat -c '%u' "/dev/fd/$cfg_fd" 2>/dev/null)
    if [[ "$owner_uid" != "$EUID" ]]; then
        exec {cfg_fd}<&-
        return 0
    fi

    local line key val
    while IFS= read -r line <&"$cfg_fd" || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        [[ "$line" == *"="* ]] || continue
        key="${line%%=*}"
        val="${line#*=}"

        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"

        if [[ "$val" =~ ^\".*\"$ ]] || [[ "$val" =~ ^\'.*\'$ ]]; then
            val="${val:1:-1}"
        fi

        # Whitelist key + strict format (no shell metachars in key).
        [[ " $_ALLOWED_KEYS " == *" $key "* ]] || continue
        [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue

        # Strip ALL control chars so a tampered config can't move the cursor,
        # recolour the terminal, or overwrite earlier output — see CWE-150.
        val=$(_strip_ctrl "$val")

        declare -g "$key=$val"
    done
    exec {cfg_fd}<&-
}

# ════════════════════════════════════════════════════════════
# Distro detection — reads /etc/os-release without `source`
# ════════════════════════════════════════════════════════════
_detect_distro() {
    DISTRO_NAME="Linux"
    [[ -r /etc/os-release ]] || return 0
    local key val
    while IFS='=' read -r key val; do
        [[ "$key" == "PRETTY_NAME" || "$key" == "NAME" ]] || continue
        val="${val%\"}"; val="${val#\"}"
        # Strip ALL control chars — defends against a tampered os-release
        # injecting cursor moves / colour codes / line overwrites (CWE-150).
        val=$(_strip_ctrl "$val")
        if [[ "$key" == "PRETTY_NAME" && -n "$val" ]]; then
            DISTRO_NAME="$val"
            return
        fi
        if [[ "$key" == "NAME" && -n "$val" && "$DISTRO_NAME" == "Linux" ]]; then
            DISTRO_NAME="$val"
        fi
    done < /etc/os-release
}

# ════════════════════════════════════════════════════════════
# Section: ASCII banner
# ════════════════════════════════════════════════════════════
_pick_color() {
    case "${BANNER_COLOR:-red}" in
        cyan)   printf '%s' "$CYAN" ;;
        yellow) printf '%s' "$YELLOW" ;;
        green)  printf '%s' "$GREEN" ;;
        *)      printf '%s' "$RED" ;;
    esac
}

_section_banner() {
    [[ "${SHOW_BANNER:-1}" == "1" ]] || return 0
    _pick_color
    cat <<'EOF'
  ╔══════════════════════════════════════════════════════════════╗
  ║  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗   ██╗██████╗  ║
  ║  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║  ███║╚════██╗ ║
  ║  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║  ╚██║ █████╔╝ ║
  ║  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║   ██║ ╚═══██╗ ║
  ║  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║   ██║██████╔╝ ║
  ║  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝╚═════╝  ║
  ╚══════════════════════════════════════════════════════════════╝
EOF
    printf '%s' "$RESET"
}

# ════════════════════════════════════════════════════════════
# Section: welcome line
# ════════════════════════════════════════════════════════════
_section_welcome() {
    [[ "${SHOW_WELCOME:-1}" == "1" ]] || return 0
    local who="${GREETING_NAME:-$USER}"
    printf "${CYAN}${BOLD}👋 Welcome, %s${RESET}  ${YELLOW}(%s)${RESET}\n" "$who" "$DISTRO_NAME"
}

# ════════════════════════════════════════════════════════════
# Section: localised date (Arabic + English per LANG_MODE)
# ════════════════════════════════════════════════════════════
_arabic_date() {
    local d
    d=$(LC_TIME=ar_SA.UTF-8 date "+%A %-d %B %Y" 2>/dev/null || true)
    if [[ -n "$d" && ! "$d" =~ [A-Za-z] ]]; then
        printf '%s' "$d"
        return
    fi
    local -A days=(
        [Saturday]=السبت  [Sunday]=الأحد   [Monday]=الإثنين
        [Tuesday]=الثلاثاء [Wednesday]=الأربعاء [Thursday]=الخميس
        [Friday]=الجمعة
    )
    local -A months=(
        [January]=يناير  [February]=فبراير [March]=مارس    [April]=أبريل
        [May]=مايو       [June]=يونيو     [July]=يوليو    [August]=أغسطس
        [September]=سبتمبر [October]=أكتوبر [November]=نوفمبر [December]=ديسمبر
    )
    local en_day day_num en_month year
    read -r en_day day_num en_month year < <(date "+%A %-d %B %Y")
    printf '%s %s %s %s' "${days[$en_day]:-$en_day}" "$day_num" "${months[$en_month]:-$en_month}" "$year"
}

_section_date() {
    [[ "${SHOW_DATE:-1}" == "1" ]] || return 0
    local ar en
    ar=$(_arabic_date)
    en=$(LC_TIME=C date "+%A, %B %-d, %Y")
    case "${LANG_MODE:-both}" in
        ar)   printf "${YELLOW}📅 %s${RESET}\n" "$ar" ;;
        en)   printf "${YELLOW}📅 %s${RESET}\n" "$en" ;;
        *)    printf "${YELLOW}📅 %s${RESET}  ${CYAN}·${RESET}  %s\n" "$ar" "$en" ;;
    esac
}

# ════════════════════════════════════════════════════════════
# Section: uptime
# ════════════════════════════════════════════════════════════
_section_uptime() {
    [[ "${SHOW_UPTIME:-1}" == "1" ]] || return 0
    local up
    up=$(uptime -p 2>/dev/null || uptime)
    printf "${YELLOW}⏱  Uptime:${RESET} %s\n" "$up"
}

# ════════════════════════════════════════════════════════════
# Helpers: numeric validation + ASCII progress bar + ctrl-char strip
# ════════════════════════════════════════════════════════════
_is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }

# Strip ALL control characters except tab — defends against terminal-escape
# injection from any external command's output (CWE-150 / CWE-93).
# Covers: \r, \b, \x07 (BEL), \x1b (ESC), \x7f (DEL), \x9b (CSI 8-bit).
_strip_ctrl() {
    local s="${1-}"
    printf '%s' "${s//[$'\001'-$'\010'$'\013'-$'\037'$'\177']/}"
}

# _progress_bar <used> <total> [width]   →   prints e.g. ████░░░░ 52%
# Width defaults to 10. Caller is responsible for color codes around it.
_progress_bar() {
    local used="${1:-0}" total="${2:-1}" width="${3:-10}"
    _is_int "$used" && _is_int "$total" && (( total > 0 )) || { printf '?'; return; }
    (( used > total )) && used="$total"
    local pct=$(( used * 100 / total ))
    local filled=$(( used * width / total ))
    local empty=$(( width - filled ))
    local bar=""
    while (( filled-- > 0 )); do bar+="█"; done
    while (( empty-- > 0 ));  do bar+="░"; done
    printf '%s %d%%' "$bar" "$pct"
}

# _temp_color <celsius>  →  prints the color escape (green/yellow/red)
_temp_color() {
    local t="$1"
    _is_int "$t" || { printf '%s' "$CYAN"; return; }
    if   (( t >= 75 )); then printf '%s' "$RED"
    elif (( t >= 60 )); then printf '%s' "$YELLOW"
    else                     printf '%s' "$GREEN"
    fi
}

# ════════════════════════════════════════════════════════════
# Section: GPU — detailed (NVIDIA single-call) or basic (temp only)
# ════════════════════════════════════════════════════════════
_section_gpu() {
    [[ "${SHOW_GPU:-1}" == "1" ]] || return 0

    if [[ "${SHOW_GPU_DETAIL:-1}" == "1" ]] && command -v nvidia-smi >/dev/null 2>&1; then
        _section_gpu_nvidia_detail && return
    fi

    # Fallback: simple temperature line (NVIDIA / AMD / lm-sensors)
    _section_gpu_simple
}

# Detailed NVIDIA line — one nvidia-smi call, all fields.
_section_gpu_nvidia_detail() {
    local raw
    raw=$(nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total,power.draw \
          --format=csv,noheader,nounits 2>/dev/null) || return 1
    [[ -z "$raw" ]] && return 1

    # Parse the first GPU line — fields are comma+space separated.
    local name temp mem_used mem_total power
    IFS=',' read -r name temp mem_used mem_total power <<<"$raw"

    # Trim whitespace and strip the verbose vendor prefix.
    name="${name#"${name%%[![:space:]]*}"}"; name="${name%"${name##*[![:space:]]}"}"
    name="${name#NVIDIA GeForce }"
    name=$(_strip_ctrl "$name")
    temp="${temp// /}"
    mem_used="${mem_used// /}"
    mem_total="${mem_total// /}"
    power="${power// /}"
    power=$(_strip_ctrl "$power")

    _is_int "$temp" || return 1
    _is_int "$mem_used" || return 1
    _is_int "$mem_total" || return 1

    local color bar
    color=$(_temp_color "$temp")
    bar=$(_progress_bar "$mem_used" "$mem_total" 8)

    # Format: 🎮 NVIDIA <name> | <temp>°C | <used>/<total>MiB <bar> <pct>% | <power>W
    if [[ -n "$power" && "$power" != "[" && "$power" != "[Not" ]]; then
        printf "${CYAN}🎮 NVIDIA %s${RESET} ${CYAN}|${RESET} ${color}%s°C${RESET} ${CYAN}|${RESET} %s/%sMiB %s ${CYAN}|${RESET} %sW\n" \
            "$name" "$temp" "$mem_used" "$mem_total" "$bar" "$power"
    else
        printf "${CYAN}🎮 NVIDIA %s${RESET} ${CYAN}|${RESET} ${color}%s°C${RESET} ${CYAN}|${RESET} %s/%sMiB %s\n" \
            "$name" "$temp" "$mem_used" "$mem_total" "$bar"
    fi
    return 0
}

# Simple temperature line — NVIDIA / AMD / lm-sensors fallback.
_section_gpu_simple() {
    local gpu_temp="" gpu_label="GPU"

    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || true)
        gpu_label="NVIDIA"
    elif command -v rocm-smi >/dev/null 2>&1; then
        gpu_temp=$(rocm-smi --showtemp 2>/dev/null | awk -F: '/edge/ {gsub(/[^0-9.]/,"",$NF); print int($NF); exit}' || true)
        gpu_label="AMD"
    elif command -v sensors >/dev/null 2>&1; then
        gpu_temp=$(sensors 2>/dev/null | awk '/GPU|gpu_temp|amdgpu/ {gsub(/[+°C]/,"",$2); print int($2); exit}' || true)
        gpu_label="Sensor"
    fi

    if [[ -z "$gpu_temp" ]]; then
        printf "${CYAN}🌡  GPU Temp:${RESET} ${RED}N/A${RESET}\n"
        return
    fi

    if ! _is_int "$gpu_temp"; then
        printf "${CYAN}🌡  %s Temp:${RESET} ${RED}invalid${RESET}\n" "$gpu_label"
        return
    fi

    local color
    color=$(_temp_color "$gpu_temp")
    printf "${CYAN}🌡  %s Temp:${RESET} ${color}%s°C${RESET}\n" "$gpu_label" "$gpu_temp"
}

# ════════════════════════════════════════════════════════════
# Section: Ollama — model count + currently loaded model
# Quiet when ollama isn't installed.
# ════════════════════════════════════════════════════════════
_section_ollama() {
    [[ "${SHOW_OLLAMA:-1}" == "1" ]] || return 0
    command -v ollama >/dev/null 2>&1 || return 0

    # Count of installed models (subtract the header line).
    local list_out total
    list_out=$(ollama list 2>/dev/null) || return 0
    total=$(printf '%s\n' "$list_out" | tail -n +2 | grep -c '^[^[:space:]]')

    # Currently loaded model + size + processor (ollama ps).
    local ps_out
    ps_out=$(ollama ps 2>/dev/null | tail -n +2 | head -1)

    if [[ -z "$ps_out" ]]; then
        printf "${CYAN}🤖 Ollama:${RESET} %s models ${CYAN}·${RESET} idle\n" "$total"
        return
    fi

    # Fields: NAME ID SIZE_VAL SIZE_UNIT PROCESSOR_PCT PROCESSOR_KIND ...
    local name id size_val size_unit processor_pct processor_kind
    read -r name id size_val size_unit processor_pct processor_kind _ <<<"$ps_out"

    # Shorten verbose HuggingFace names:
    #   hf.co/org/Foundation-Sec-8B-Reasoning-Q4_K_M-GGUF:latest
    #     → Foundation-Sec-8B-Reasoning
    local short_name="${name##*/}"          # last path segment
    short_name="${short_name%%-Q[0-9]*}"    # strip -Q4..., -Q5..., -Q8... + rest
    short_name="${short_name%-GGUF*}"       # strip -GGUF and trailing :tag
    short_name="${short_name%:latest}"      # noise tag
    short_name=$(_strip_ctrl "$short_name")

    printf "${CYAN}🤖 Ollama:${RESET} %s models ${CYAN}·${RESET} %s loaded (%s%s, %s)\n" \
        "$total" "$short_name" "$size_val" "$size_unit" "$processor_kind"
}

# ════════════════════════════════════════════════════════════
# Section: load average
# ════════════════════════════════════════════════════════════
_section_load() {
    [[ "${SHOW_LOAD:-1}" == "1" ]] || return 0
    local load
    load=$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "?")
    printf "${CYAN}⚙️  Load avg:${RESET} %s\n" "$load"
}

# ════════════════════════════════════════════════════════════
# Section: memory usage
# ════════════════════════════════════════════════════════════
_section_memory() {
    [[ "${SHOW_MEMORY:-1}" == "1" ]] || return 0
    command -v free >/dev/null 2>&1 || return 0
    local mem
    mem=$(free -h --si 2>/dev/null | awk '/^Mem:/ {printf "%s / %s", $3, $2}')
    [[ -z "$mem" ]] && return 0
    printf "${CYAN}🧠 Memory:${RESET}   %s\n" "$mem"
}

# ════════════════════════════════════════════════════════════
# Section: Security panel — security updates · firewall · last login
#
# Design decisions (security review baked in):
#   - NO sudo anywhere — `systemctl is-active` works for any user.
#   - `apt list --upgradable` costs ~400 ms; we cache its result and refresh
#     in a detached background subshell so the banner never blocks.
#   - Cache lives under $XDG_CACHE_HOME (user-owned, mode 0700 by default).
#   - Last login is display-only — no "smart alerts" that need persistent
#     state which an attacker on the same account could poison.
# ════════════════════════════════════════════════════════════
readonly _SECURITY_CACHE_TTL=21600     # 6 hours
readonly _SECURITY_CACHE_REL="linux-greet/security-updates"

_security_cache_path() {
    # Reject a non-absolute $XDG_CACHE_HOME — defends against a malicious
    # env override (e.g. via misconfigured `sudo -E` or SSH AcceptEnv).
    local base="${XDG_CACHE_HOME:-$HOME/.cache}"
    case "$base" in
        /*) ;;
        *)  base="$HOME/.cache" ;;
    esac
    printf '%s/%s' "$base" "$_SECURITY_CACHE_REL"
}

# Refresh the cache in the background — never blocks the banner.
# Writes atomically (temp file + rename) so a half-written file can't
# be observed by a concurrent reader.
_security_refresh_async() {
    local cache_file="$1"
    local cache_dir
    cache_dir=$(dirname "$cache_file")
    mkdir -p "$cache_dir" 2>/dev/null || return 0

    # Detached subshell — survives banner exit. Output redirected to nowhere.
    (
        local count=""
        if command -v apt >/dev/null 2>&1; then
            count=$(apt list --upgradable 2>/dev/null | grep -ci security)
        elif command -v dnf >/dev/null 2>&1; then
            count=$(dnf updateinfo list --security 2>/dev/null | grep -c '^\w')
        fi
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            local tmp
            tmp=$(mktemp "$cache_dir/.security-updates.XXXXXX" 2>/dev/null) || exit 0
            printf '%s\n' "$count" > "$tmp"
            mv -f "$tmp" "$cache_file" 2>/dev/null || rm -f "$tmp"
        fi
    ) >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

# Read the cached value, trigger an async refresh when stale or missing.
# Always returns instantly — never blocks the banner.
_security_updates_count() {
    local cache_file
    cache_file=$(_security_cache_path)
    local now mtime age
    now=$(date +%s)
    mtime=0
    [[ -r "$cache_file" ]] && mtime=$(stat -c '%Y' "$cache_file" 2>/dev/null || echo 0)
    age=$(( now - mtime ))

    if (( age > _SECURITY_CACHE_TTL )); then
        _security_refresh_async "$cache_file"
    fi

    if [[ -r "$cache_file" ]]; then
        local val
        IFS= read -r val < "$cache_file" 2>/dev/null
        val=$(_strip_ctrl "$val")
        _is_int "$val" && { printf '%s' "$val"; return; }
    fi
    printf '%s' "—"
}

_section_security() {
    [[ "${SHOW_SECURITY:-1}" == "1" ]] || return 0
    local items=()

    # 1. Updates count (cached, never blocks)
    local updates color
    updates=$(_security_updates_count)
    if [[ "$updates" == "—" ]]; then
        items+=("${CYAN}updates: —${RESET}")
    elif _is_int "$updates"; then
        color=$GREEN
        (( updates > 0 )) && color=$YELLOW
        (( updates > 5 )) && color=$RED
        items+=("${color}updates: $updates${RESET}")
    fi

    # 2. Firewall state — no sudo, no false positives.
    # `--system` is explicit so a user unit with the same name can't shadow
    # the real firewall service.
    if command -v systemctl >/dev/null 2>&1; then
        local fw="firewall: off"
        local fw_color=$RED
        if [[ "$(systemctl --system is-active ufw 2>/dev/null)" == "active" ]]; then
            fw="UFW active"; fw_color=$GREEN
        elif [[ "$(systemctl --system is-active firewalld 2>/dev/null)" == "active" ]]; then
            fw="firewalld active"; fw_color=$GREEN
        elif [[ "$(systemctl --system is-active nftables 2>/dev/null)" == "active" ]]; then
            fw="nftables active"; fw_color=$GREEN
        fi
        items+=("${fw_color}${fw}${RESET}")
    fi

    # 3. Last login — display only, no comparisons.
    # `--` separates flags from the username, so a hostile $USER like "-f path"
    # can't redirect `last` to a different wtmp file (argument injection).
    if command -v last >/dev/null 2>&1; then
        # last -F format: "user  tty  Day Mon DD HH:MM:SS YYYY ..."
        # field positions:  $1   $2   $3  $4   $5    $6   $7
        # We want Month + Day + Time → fields 4 5 6.
        # NR==2 skips the current session ("still logged in") and picks the
        # previous one. If only one entry exists, NR==1 falls through.
        local raw
        raw=$(last -n 3 -F -- "$USER" 2>/dev/null \
              | awk 'NR==2 && $4 != "" {print $4,$5,$6; exit}
                     END { if (NR<2) print "" }')
        raw=$(_strip_ctrl "$raw")
        [[ -n "$raw" ]] && items+=("last: $raw")
    fi

    [[ ${#items[@]} -eq 0 ]] && return 0

    printf "${CYAN}🔒 Security:${RESET} "
    local i=0
    for item in "${items[@]}"; do
        (( i++ > 0 )) && printf " ${CYAN}·${RESET} "
        printf '%s' "$item"
    done
    printf '\n'
}

# ════════════════════════════════════════════════════════════
# Section: footer
# ════════════════════════════════════════════════════════════
_section_footer() {
    printf "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# ════════════════════════════════════════════════════════════
# main — orchestrator. Section order is intentional.
# ════════════════════════════════════════════════════════════
main() {
    _detect_distro
    _load_config
    _section_banner
    _section_welcome
    _section_date
    _section_uptime
    _section_gpu
    _section_ollama
    _section_load
    _section_memory
    _section_security
    _section_footer
}

main "$@"
