# linux-greet

> A friendly bilingual (Arabic / English) terminal banner for Linux.
> Shows distro · date · uptime · GPU dashboard · Ollama · load · memory · security — every time you open a terminal. No sudo required.

```
╔══════════════════════════════════════════════════════════════╗
║ ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗ ██╗ ██╗██████╗  ║
║ ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗ ██║ ███║╚════██╗ ║
║ ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║ ╚██║ █████╔╝ ║
║ ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║  ██║ ╚═══██╗ ║
║ ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║  ██║██████╔╝ ║
║ ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═╝╚═════╝  ║
╚══════════════════════════════════════════════════════════════╝
👋 Welcome, alice (Debian GNU/Linux 13 (trixie))
📅 الثلاثاء 19 مايو 2026 · Tuesday, May 19, 2026
⏱  Uptime: up 1 day, 5 hours, 32 minutes
🎮 NVIDIA RTX 2060 SUPER | 44°C | 5772/8192MiB █████░░░ 70% | 4.49W
🤖 Ollama: 9 models · llama3:8b loaded (5.2 GB, GPU)
⚙️  Load avg: 0.56  0.58  0.55
🧠 Memory: 8.7G / 67G
🔒 Security: updates: 0 · UFW active · last: May 17 22:24:35
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ✨ Features

- **Distro auto-detect** from /etc/os-release (Debian, Ubuntu, Fedora, Arch, ...)
- **Bilingual date** — Arabic + English, with graceful fallback if ar_SA.UTF-8 locale isn't installed
- **GPU dashboard** — NVIDIA detail mode shows name, temperature, VRAM bar, and power draw in one line
- **AMD & generic GPU** fallback via rocm-smi or lm-sensors
- **Ollama integration** — shows installed model count + currently loaded model (auto-hidden if not installed)
- **Security panel** — pending security updates, active firewall, last login (no sudo required, cached)
- **Color-coded temps**: green <60°C, yellow 60-74°C, red ≥75°C
- **Config file** — ~/.config/linux-greet/config.sh controls every section
- **Modular** — toggle any section on/off independently
- **No external deps** — pure bash + standard core utils
- **Idempotent** — shows once per shell session via the optional shell hook

## 📦 Installation

```bash
# 1. Clone or download
git clone https://github.com/ABDUAZIZX/linux-greet.git
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

Adjust the path inside the hook to wherever you placed `linux-greet.sh`.

## 🌍 Arabic locale (optional, recommended)

If you want the Arabic date instead of the English fallback:

```bash
sudo apt install locales
sudo dpkg-reconfigure locales   # pick: ar_SA.UTF-8
```

## 🛠 Configuration

linux-greet reads its config from ~/.config/linux-greet/config.sh.

Start by copying the example:

```bash
mkdir -p ~/.config/linux-greet
cp config.example.sh ~/.config/linux-greet/config.sh
```

Edit the file to toggle sections, switch language mode, or change the banner color.
The parser is whitelist-based — unknown keys are silently ignored, so the config
is forward-compatible across versions.

To customize the ASCII banner itself, edit the _section_banner function in
linux-greet.sh. Generate new banner text at
[patorjk.com/software/taag](https://patorjk.com/software/taag/) using the
ANSI Shadow font.

## 🛡 Defensive coding

linux-greet runs on every shell startup, so it follows defensive patterns
even though it has no privileged access:

- Config is parsed with a whitelist, never source'd
- External command output is sanitized before display
- File ownership checked via descriptor (not path) to avoid races

Security notes in [SECURITY.md](./SECURITY.md).

## 🧪 Tested on

- Debian 13 (trixie) · bash 5.2 / zsh 5.9 · WezTerm, GNOME Terminal
- Fedora 43 KDE · bash 5.2 · Konsole
- Works on any modern Linux with bash 4+

## 📜 License

MIT — do whatever you want, attribution welcome.

## 🤝 Contributing

PRs welcome for:

- More distro banners (Ubuntu, Fedora, Arch, ...)
- Additional locales (French, Spanish, ...)
- macOS support

---

# linux-greet — العربية

شعار ترحيب ثنائي اللغة لأي terminal على Linux. يعرض اسم النظام، تاريخ اليوم
بالعربية والإنجليزية، uptime، تفاصيل GPU، نماذج Ollama، تحديثات الأمن،
حمل الـ CPU، والذاكرة — كل مرة تفتح terminal.

## ✨ الميزات

- اكتشاف distro تلقائي من /etc/os-release
- تاريخ ثنائي اللغة (عربي + إنجليزي) مع fallback إذا لم يكن locale العربي مثبّتاً
- لوحة GPU مفصّلة لـ NVIDIA: الاسم، الحرارة، شريط VRAM، الطاقة
- دعم AMD عبر rocm-smi وأي GPU عبر lm-sensors
- تكامل Ollama: عدد النماذج + النموذج المحمّل حالياً (يختفي تلقائياً إذا غير مثبّت)
- لوحة أمنية: عدد التحديثات الأمنية، حالة الجدار الناري، آخر تسجيل دخول
  (بدون sudo، مع cache)
- ملف إعدادات في ~/.config/linux-greet/config.sh يتحكم بكل قسم
- ألوان تفاعلية للحرارة: أخضر <60°C، أصفر 60-74°C، أحمر ≥75°C
- bash نقي، بدون تبعيات خارجية
- يعمل مرة واحدة فقط لكل terminal session

## 📦 التثبيت السريع

```bash
git clone https://github.com/ABDUAZIZX/linux-greet.git ~/linux-greet
chmod +x ~/linux-greet/linux-greet.sh

# نسخ ملف الإعدادات
mkdir -p ~/.config/linux-greet
cp ~/linux-greet/config.example.sh ~/.config/linux-greet/config.sh

# للتشغيل التلقائي، انسخ block التشغيل من قسم Installation أعلاه
```

## 🛡 برمجة دفاعية

linux-greet يعمل عند كل فتح للـ terminal، لذا يتّبع أنماطاً دفاعية حتى أنه
لا يطلب أي صلاحيات مرفوعة:

- ملف الإعدادات يُقرأ عبر whitelist، ولا يُمرَّر لـ source أبداً
- مخرجات الأوامر الخارجية تُنظَّف من رموز التحكم قبل العرض
- ملكية الملف تُفحص عبر file descriptor لتجنّب race conditions

تفاصيل أمنية في [SECURITY.md](./SECURITY.md).
