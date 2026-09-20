<div align="center">

# 🔒 KPixie

**An implementation of [xCaptaiN09](https://github.com/xCaptaiN09/)'s [Pixie SDDM](https://github.com/xCaptaiN09/pixie-sddm) theme for kscreenlocker.**

[![License: GPL-v2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)
[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-cyan.svg)](https://kde.org/plasma-desktop/)
[![Style](https://img.shields.io/badge/Design-Material%20Design%203-7b2cbf.svg)](https://m3.material.io/)

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

- 📱 **Pixel Aesthetic:** Clean typography and a iconic two-tone stacked clock.
- 🎨 **Material You Dynamic Colors:** Intelligent color extraction that samples your wallpaper for UI accents.
- 🌫️ **Next-Gen Blur:** High-performance Gaussian blur.
- 👤 **Circular Avatar:** Canvas-rendered crisp profile picture.
- 🃏 **Material Design 3:** Dark card UI with smooth interactions and responsive dropdowns.
- ⚙️ **Native Plasma Controls:** Full integration with system suspend, user switching, virtual keyboard, and battery status.

---

## 🚀 Installation

Run the following commands in your terminal:

```bash
# Clone the repository
git clone [https://github.com/Marlon554/kpixie-kscreenlocker.git](https://github.com/Marlon554/kpixie-kscreenlocker.git)

# Navigate to directory
cd kpixie-kscreenlocker

# Make installer executable & run
chmod +x install.sh
./install.sh
