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
SHOW_LOAD=1
SHOW_MEMORY=1
LANG_MODE=both        # ar | en | both
BANNER_COLOR=red      # red | cyan | yellow | green
GREETING_NAME=""      # if empty, falls back to $USER

# Whitelist of config keys (space-separated).
# Parsing never executes config content — values are matched against this list.
readonly _ALLOWED_KEYS="SHOW_BANNER SHOW_WELCOME SHOW_DATE SHOW_UPTIME SHOW_GPU SHOW_LOAD SHOW_MEMORY LANG_MODE BANNER_COLOR GREETING_NAME"

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

        # Strip ANSI escapes from values so a tampered config can't move the
        # cursor or recolour the terminal — see CWE-150.
        val="${val//$'\033'/}"

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
        # Strip ANSI escape sequences — defends against a tampered os-release
        # that could inject cursor moves / colour codes into our banner (CWE-150).
        val="${val//$'\033'/}"
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
# Section: GPU temperature (NVIDIA / AMD / lm-sensors fallback)
# ════════════════════════════════════════════════════════════
_section_gpu() {
    [[ "${SHOW_GPU:-1}" == "1" ]] || return 0
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

    # Numeric validation before arithmetic comparison.
    if [[ ! "$gpu_temp" =~ ^[0-9]+$ ]]; then
        printf "${CYAN}🌡  %s Temp:${RESET} ${RED}invalid${RESET}\n" "$gpu_label"
        return
    fi

    local color
    if   (( gpu_temp >= 75 )); then color=$RED
    elif (( gpu_temp >= 60 )); then color=$YELLOW
    else                            color=$GREEN
    fi
    printf "${CYAN}🌡  %s Temp:${RESET} ${color}%s°C${RESET}\n" "$gpu_label" "$gpu_temp"
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
    _section_load
    _section_memory
    _section_footer
}

main "$@"
