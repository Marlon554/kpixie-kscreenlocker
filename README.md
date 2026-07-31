<div align="center">

# 🔒 K Pixie Lock

**A clean, modern, and minimal kscreenlocker theme inspired by Google Pixel UI and Material Design 3.**

[![License: GPL-v2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)
[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-cyan.svg)](https://kde.org/plasma-desktop/)
[![Style](https://img.shields.io/badge/Design-Material%20Design%203-7b2cbf.svg)](https://m3.material.io/)

*A fork of [Pixie SDDM](https://github.com/xCaptaiN09/pixie-sddm) tailored for native KDE Plasma lock screen experience.*

<br />

<p align="center">
  <img src="screenshots/Lock Screen.png" width="48%" alt="Lock Screen Preview" />
  <img src="screenshots/Login Card.png" width="48%" alt="Login Screen Preview" />
</p>

</div>

---

> [!CAUTION]
> **Critical System Files Notice:** This project modifies system files in `/usr/share/plasma`. Improper configuration can result in being locked out of your desktop session.
>
> **Do not log out immediately after installation.** Verify the QML logic first by running the greeter test command for your distribution:
>
> - **Arch Linux:** `/usr/lib/kscreenlocker_greet --testing`
> - **Fedora:** `/usr/lib64/kscreenlocker_greet --testing`
> - **Debian / Ubuntu:** `/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing`

---

## ✨ Features

- 📱 **Pixel Aesthetic:** Clean typography featuring the iconic two-tone stacked clock.
- 🎨 **Plasma Accent Integration:** Dynamically adapts to your system accent color set in *System Settings → Appearance → Colors*.
- 🃏 **Material Design 3 UI:** Elevated dark card layout with smooth animations and touch/press interactions.
- 👤 **Circular Avatar:** Canvas-rendered crisp profile picture.
- ⚙️ **Native Plasma Controls:** Full integration with system suspend, user switching, virtual keyboard, and battery status.
- ⌨️ **Keyboard Navigation:** Native `Tab` cycling between fields and `Enter` key execution.

---

## 🚀 Installation

Run the following commands in your terminal:

```bash
# Clone the repository
git clone [https://github.com/Marlon554/pixie-kde-lock.git](https://github.com/Marlon554/pixie-kde-lock.git)

# Navigate to directory
cd pixie-kde-lock

# Make installer executable & run
chmod +x install.sh
./install.sh
