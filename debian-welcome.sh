#!/usr/bin/env bash
# debian-welcome — a friendly Linux terminal banner.
# Shows: distro name in ASCII · localised date · uptime · GPU temp (if available).
# Tested on Debian 13 but works on any Linux with bash >= 4.0.
#
# License: MIT
# Source : https://github.com/azoz8/debian-welcome   (replace after fork)

set -uo pipefail

# ── ANSI colors ──────────────────────────────────────────────
RED=$'\033[1;31m'
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[1;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── distro auto-detect ───────────────────────────────────────
DISTRO_NAME="Linux"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_NAME="${PRETTY_NAME:-${NAME:-Linux}}"
fi

# ── ASCII banner (DEBIAN 13 — change to taste) ───────────────
printf '%s' "$RED"
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

# ── greeting ─────────────────────────────────────────────────
printf "${CYAN}${BOLD}👋 Welcome, %s${RESET}  ${YELLOW}(%s)${RESET}\n" "$USER" "$DISTRO_NAME"

# ── localised date (Arabic when ar_SA available, English fallback) ────
arabic_date=$(LC_TIME=ar_SA.UTF-8 date "+%A %-d %B %Y" 2>/dev/null || true)
if [[ -z "$arabic_date" || "$arabic_date" =~ [A-Za-z] ]]; then
    declare -A days=(
        [Saturday]=السبت  [Sunday]=الأحد   [Monday]=الإثنين
        [Tuesday]=الثلاثاء [Wednesday]=الأربعاء [Thursday]=الخميس
        [Friday]=الجمعة
    )
    declare -A months=(
        [January]=يناير  [February]=فبراير [March]=مارس    [April]=أبريل
        [May]=مايو       [June]=يونيو     [July]=يوليو    [August]=أغسطس
        [September]=سبتمبر [October]=أكتوبر [November]=نوفمبر [December]=ديسمبر
    )
    read -r en_day day_num en_month year < <(date "+%A %-d %B %Y")
    arabic_date="${days[$en_day]:-$en_day} $day_num ${months[$en_month]:-$en_month} $year"
fi
en_date=$(LC_TIME=C date "+%A, %B %-d, %Y")
printf "${YELLOW}📅 ${arabic_date}${RESET}  ${CYAN}·${RESET}  ${en_date}\n"

# ── uptime ───────────────────────────────────────────────────
up=$(uptime -p 2>/dev/null || uptime)
printf "${YELLOW}⏱  Uptime:${RESET} %s\n" "$up"

# ── GPU temperature: NVIDIA, then AMD, else N/A ──────────────
gpu_temp=""
gpu_label="GPU"

if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || true)
    gpu_label="NVIDIA"
elif command -v rocm-smi >/dev/null 2>&1; then
    # AMD: rocm-smi prints "Temperature (Sensor edge) (C): NN.0"
    gpu_temp=$(rocm-smi --showtemp 2>/dev/null | awk -F: '/edge/ {gsub(/[^0-9.]/,"",$NF); print int($NF); exit}' || true)
    gpu_label="AMD"
elif command -v sensors >/dev/null 2>&1; then
    # Generic fallback: integrated GPU temp via lm-sensors
    gpu_temp=$(sensors 2>/dev/null | awk '/GPU|gpu_temp|amdgpu/ {gsub(/[+°C]/,"",$2); print int($2); exit}' || true)
    gpu_label="Sensor"
fi

if [[ -z "${gpu_temp:-}" ]]; then
    printf "${CYAN}🌡  GPU Temp:${RESET} ${RED}N/A${RESET}\n"
else
    if   (( gpu_temp >= 75 )); then color=$RED
    elif (( gpu_temp >= 60 )); then color=$YELLOW
    else                            color=$GREEN
    fi
    printf "${CYAN}🌡  %s Temp:${RESET} ${color}%s°C${RESET}\n" "$gpu_label" "$gpu_temp"
fi

# ── CPU load (always available) ──────────────────────────────
load=$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "?")
printf "${CYAN}⚙️  Load avg:${RESET} %s\n" "$load"

# ── memory used ──────────────────────────────────────────────
if command -v free >/dev/null 2>&1; then
    mem=$(free -h --si | awk '/^Mem:/ {printf "%s / %s", $3, $2}')
    printf "${CYAN}🧠 Memory:${RESET}   %s\n" "$mem"
fi

printf "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
