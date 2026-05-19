# linux-greet

> A friendly bilingual (Arabic / English) terminal banner for Linux.
> Shows distro · date · uptime · GPU dashboard · Ollama · load · memory · security — every time you open a terminal. No sudo required.

```
╔══════════════════════════════════════════════════════════════╗
║  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗   ██╗██████╗  ║
║  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║  ███║╚════██╗ ║
║  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║  ╚██║ █████╔╝ ║
║  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║   ██║ ╚═══██╗ ║
║  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║   ██║██████╔╝ ║
║  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝╚═════╝  ║
╚══════════════════════════════════════════════════════════════╝
👋 Welcome, alice  (Debian GNU/Linux 13 (trixie))
📅 الثلاثاء 19 مايو 2026  ·  Tuesday, May 19, 2026
⏱  Uptime: up 1 day, 5 hours, 32 minutes
🎮 NVIDIA RTX 2060 SUPER | 44°C | 5772/8192MiB █████░░░ 70% | 4.49W
🤖 Ollama: 9 models · **** loaded (5.2GB, GPU)
⚙️  Load avg: 0.56 0.58 0.55
🧠 Memory:   8.7G / 67G
🔒 Security: updates: 0 · UFW active · last: May 17 22:24:35
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ✨ Features

- **Distro auto-detect** from `/etc/os-release` (Debian, Ubuntu, Fedora, Arch, ...).
- **Bilingual date** — Arabic + English, with English fallback when `ar_SA.UTF-8` locale isn't installed.
- **NVIDIA GPU dashboard** — name, temperature, VRAM usage with progress bar, power draw — all from a single `nvidia-smi` call.
- **AMD / lm-sensors fallback** if NVIDIA isn't present.
- **Ollama integration** — installed model count and the model currently loaded into VRAM (auto-hidden when ollama isn't installed).
- **Security panel** — pending security updates, firewall state (UFW/firewalld/nftables), last login — all **without sudo**.
- **Color-coded temperatures**: green < 60°C, yellow 60-74°C, red ≥ 75°C.
- **Modular sections** — every section can be toggled via `~/.config/linux-greet/config.sh`.
- **Safe config parser** — whitelist + regex, never `source`s your config, owner-checked via file descriptor (defends CWE-362 TOCTOU).
- **Async background refresh** for the slow `apt list` query — the banner never blocks.
- **No external deps required** — pure bash + standard core utils.
- **Idempotent shell hook** — shows once per session, never duplicates.

## 📦 Installation

```bash
# 1. Clone or download
git clone https://github.com/azoz8/linux-greet.git
cd linux-greet

# 2. Make executable
chmod +x linux-greet.sh

# 3. (Optional) Run once to test
./linux-greet.sh

# 4. Auto-run on every new terminal — add to ~/.bashrc OR ~/.zshrc
cat >> ~/.zshrc <<'EOF'

# linux-greet banner — show once per interactive shell
if [[ $- == *i* ]] && [[ -z "${BANNER_SHOWN:-}" ]]; then
    [ -f "$HOME/linux-greet/linux-greet.sh" ] && \
        bash "$HOME/linux-greet/linux-greet.sh"
    export BANNER_SHOWN=1
fi
EOF
```

> Adjust the path inside the hook to wherever you placed `linux-greet.sh`.

## 🌍 Arabic locale (optional, recommended)

If you want the Arabic date instead of the English fallback:

```bash
sudo apt install locales
sudo dpkg-reconfigure locales      # pick: ar_SA.UTF-8
```

## 🛠 Customisation

Open `linux-greet.sh` and tweak:

- **Banner text** — replace the `DEBIAN 13` block letters with your distro
  (try [patorjk.com/software/taag](https://patorjk.com/software/taag/) with font `ANSI Shadow`)
- **Colors** — change the ANSI escape codes at the top
- **Sections** — comment out any you don't want (date, GPU, memory, ...)

## 🧪 Tested on

- Debian 13 (trixie) · zsh 5.9 · WezTerm
- Should work on any modern Linux with bash 4+

## 📜 License

MIT — do whatever you want, attribution welcome.

## 🤝 Contributing

PRs welcome for:
- More distro banners (Ubuntu, Fedora, Arch, ...)
- Additional locales (French, Spanish, ...)
- macOS support

---

# linux-greet — العربية

شعار ترحيب جذّاب لأي terminal على Linux. يعرض اسم النظام، تاريخ اليوم بالعربية، uptime، حرارة GPU، حمل الـ CPU، والذاكرة — كل مرة تفتح terminal.

## الميزات

- اكتشاف distro تلقائي
- تاريخ بالعربية (مع fallback إنجليزي لو locale غير مثبّت)
- يدعم NVIDIA و AMD و lm-sensors
- ألوان تفاعلية حسب الحرارة
- bash نقي، لا تبعيات خارجية
- يعمل مرة واحدة فقط لكل terminal session

## التثبيت السريع

```bash
git clone https://github.com/azoz8/linux-greet.git ~/linux-greet
chmod +x ~/linux-greet/linux-greet.sh
# للتشغيل التلقائي، انسخ block التشغيل من قسم Installation أعلاه
```
