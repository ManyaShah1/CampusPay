# CampusPay (DBIT Mumbai)

Offline-first, multi-carrier campus payment application engineered for **Don Bosco Institute of Technology (DBIT Mumbai)**.

CampusPay guarantees zero-latency, fail-safe transactions even in zero-connectivity basement canteens and crowded auditoriums using **Ultrasonic Acoustic Chirps (18.4 kHz)**, **BLE Mesh Advertisements**, and **Silent USSD (*99#)**.

---

## 📚 Project Documentation

- **[CHANGELOG.md](file:///Users/manyashah/StudioProjects/CampusPay/CHANGELOG.md)**: Full history of engineering updates, Stitch "Neon White" design system migration, downloaded asset references, and future maintenance guidelines.
- **[ARCHITECTURE.md](file:///Users/manyashah/StudioProjects/CampusPay/ARCHITECTURE.md)**: Deep dive into the tri-tier payment rails, cryptographic pre-auth pool, and dual-ledger asynchronous sync.
- **[`campuspay_architecture_poster.html`](file:///Users/manyashah/StudioProjects/CampusPay/campuspay_architecture_poster.html)**: Interactive visual blueprint of the complete CampusPay hardware & cloud ecosystem.

---

## 🎨 Design System: Stitch "Neon White"

The UI conforms to the **Stitch "Neon White"** design system:
- **Canvas**: Pure White `#FFFFFF`
- **Cards & Bento Grid**: Soft Light Gray `#F6F3F2` with 1px border stroke `#E5E2E1`
- **Primary Typography**: High-contrast Dark Charcoal `#1C1B1B`
- **Hero Wallet Card**: ID-1 Purple Gradient (`#6B21A8` → `#4C1D95`)
- **Kinetic Action Elements**: Electric Yellow `#FFE500`

---

## 🚀 Getting Started

### 1. Run Static Analysis
```bash
flutter analyze
```

### 2. Launch on Chrome (Local Preview)
```bash
flutter run -d chrome
```

### 3. Run Wirelessly on Physical Phone
```bash
# Pair device over Wi-Fi (one-time setup)
adb pair <PHONE_IP>:<PORT>

# Connect to device
adb connect <PHONE_IP>:<PORT>

# Run on target phone
flutter run -d <DEVICE_ID>
```
