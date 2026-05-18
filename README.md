# linux-greet

> A friendly bilingual (Arabic / English) terminal banner for Linux.
> Shows distro name, localised date, uptime, GPU temperature, load, memory — every time you open a terminal.

![demo](./demo.png) <!-- اختياري: التقط لقطة وأضفها هنا -->

```
╔══════════════════════════════════════════════════════════════╗
║  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗   ██╗██████╗  ║
║  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║  ███║╚════██╗ ║
║  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║  ╚██║ █████╔╝ ║
║  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║   ██║ ╚═══██╗ ║
║  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║   ██║██████╔╝ ║
║  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝╚═════╝  ║
╚══════════════════════════════════════════════════════════════╝
👋 Welcome, abduaiz  (Debian GNU/Linux 13 (trixie))
📅 الإثنين 18 مايو 2026  ·  Monday, May 18, 2026
⏱  Uptime: up 16 hours, 30 minutes
🌡  NVIDIA Temp: 41°C
⚙️  Load avg: 0.42 0.55 0.61
🧠 Memory:   6.4G / 67G
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ✨ Features

- **Distro auto-detect** from `/etc/os-release` (works on Debian, Ubuntu, Fedora, Arch, ...)
- **Date in Arabic** with English fallback when `ar_SA.UTF-8` locale isn't installed
- **GPU temperature** for NVIDIA (`nvidia-smi`), AMD (`rocm-smi`), or generic (`lm-sensors`)
- **Color-coded GPU temp**: green < 60°C, yellow 60-74°C, red ≥ 75°C
- **Load average** and **memory usage** from `/proc` and `free`
- **No external deps required** — pure bash + standard core utils
- **Idempotent**: shows once per shell session (with the optional zshrc hook)

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
