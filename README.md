# AG-SpatialPrivacy 🛡️👀

> **Spatial Privacy for macOS**: Dynamic screen blur that hides what you're working on when you look away, using AirPods head-tracking and camera fallback. Inspired by [@bryllim_](https://x.com/bryllim_/status/2099049704822907277).

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![AirPods](https://img.shields.io/badge/AirPods-Spatial%20Audio-green?logo=apple)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 🌟 Overview

When working in coffee shops, open offices, or on flights, people around you can easily look over your shoulder at your screen. 

**AG-SpatialPrivacy** solves this by tracking your head position in real-time. When you turn your head away from your laptop, the app dynamically casts a smooth, frosted-glass privacy curtain across the side of your screen you're looking away from (or the entire display), instantly shielding sensitive code, documents, and messages. As soon as you look back, the screen clears up seamlessly.

https://github.com/user-attachments/assets/demo.mp4

---

## ✨ Features

- 🎧 **AirPods Head Tracking**: Real-time 60Hz attitude tracking (yaw, pitch, roll) via Apple's `CoreMotion` (`CMHeadphoneMotionManager`).
- 📷 **Webcam Face Tracking Fallback**: Tracks head pose using Apple's `Vision` framework (`VNFaceObservation`) when AirPods are not in use.
- 🪟 **Interactive Demo / Manual Simulation**: Built-in interactive slider to test and preview the blur effect immediately without moving your head.
- 🌫️ **Hardware-Accelerated Frosted Blur**: Combines `NSVisualEffectView` and SkyLight compositor blur with feathered `CAGradientLayer` masking.
- 🖱️ **Zero-Interruption Pass-Through**: Borderless floating overlay window with `ignoresMouseEvents = true` so all typing, clicks, and gestures pass through unimpeded.
- 🎯 **One-Click Calibration**: Instantly re-zeros your neutral gaze position to suit any posture or seating arrangement.
- ⚙️ **Customizable Privacy Modes**:
  - **Auto**: Blurs the side of the display opposite your gaze.
  - **Gaze Follow**: Blurs the side you look towards.
  - **Full Screen Blur**: Blurs the entire screen whenever you look away.
  - **Appearance**: Dark Frosted Glass, Light Glass, or High-Contrast Privacy Blackout.
- 🎛️ **Native Menu Bar Extra**: Sleek macOS menu bar interface with live head-angle gauge, status badge, and quick toggles.

---

## 🚀 Quick Start

### Build & Run from Source

```bash
# Clone the repository
git clone https://github.com/1bnjmn3/AG-SpatialPrivacy.git
cd AG-SpatialPrivacy

# Build and run directly
swift run
```

### Build `.app` Bundle

```bash
# Build standalone MacBlur.app bundle
./scripts/build_app.sh

# Open the app
open MacBlur.app
```

---

## 🎧 Supported Devices

- **AirPods Pro** (1st & 2nd Generation)
- **AirPods Max**
- **AirPods** (3rd & 4th Generation with Spatial Audio)
- **Beats Fit Pro** & other Beats with Apple H1/H2 chip
- **Any Mac FaceTime / USB Camera** (fallback tracking)

---

## 📜 License

MIT License. Open source and built for the community.
