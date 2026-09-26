# CampusPay — Engineering & UI Changelog

All notable changes, design system migrations, asset ingestions, and architecture updates to **CampusPay** are documented in this file.

This document adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) standards and uses [Semantic Versioning](https://semver.org/).

---

## 📖 How to Maintain This Document (Future Reference Guide)

When contributing or making changes to CampusPay in the future, follow the [Fork & Pull Model in CONTRIBUTING.md](file:///Users/manyashah/StudioProjects/CampusPay/CONTRIBUTING.md) and use this standard procedure to keep this document up to date:

### 1. Versioning Convention
- **Major (`X.0.0`)**: Breaking architectural changes (e.g., changing offline token crypto protocol, complete navigation rewrite).
- **Minor (`0.X.0`)**: New screens, features, or design system theme updates (e.g., dark mode toggle, new payment method).
- **Patch (`0.0.X`)**: Bug fixes, asset updates, typography tweaks, or lint error resolutions.

### 2. Standard Entry Template
Copy and paste this section at the top of the **Release History** whenever you make new changes:

```markdown
## [vX.Y.Z] — YYYY-MM-DD
### 🎨 UI & Design System
- Description of visual, color token, or layout modifications.

### 📦 Assets & Resources
- Added/modified image, SVG, audio, or font assets. Specify file paths in `assets/`.

### ⚡ Logic & ViewModels
- State management, viewmodel updates, or database queries.

### 🛠️ Maintenance & Refactoring
- Code cleanup, static analysis resolution (`flutter analyze`), dependency upgrades.

### 🧪 Verification & Testing
- How the changes were tested (e.g., Chrome, physical phone via wireless ADB).
```

### 3. Categories of Changes
Always categorize your entries using these standard tags:
- `Added`: for brand new features, assets, or screens.
- `Changed`: for modifications to existing UI, colors, or logic.
- `Deprecated`: for features that will be removed in subsequent versions.
- `Removed`: for deleted code, dead assets, or obsolete dependencies.
- `Fixed`: for bug fixes or lint warnings.
- `Security`: for cryptographic updates (e.g., ECDSA tokens, Secure Storage, PIN handling).

---

## 🚀 Release History

---

## [v2.4.1] — 2026-09-26 (History Page Contrast & Universal Overflow Hardening)

### Summary
Resolved unreadable white-on-white typography on the History screen (`TransactionsLedgerScreen`) following the Stitch Neon White theme transition. Eliminated all `RenderFlex` horizontal and vertical overflow warnings across all core screens (`StudentHomeScreen`, `TransactionsLedgerScreen`, `CampusCoinsScreen`, `ScanAndPayScreen`, `EnterAmountScreen`, `ProfileSettingsScreen`, and `PaymentSuccessScreen`) on both compact mobile viewports (320px–375px) and desktop web windows.

---

### 🎨 1. History Page White Text Contrast Fixes ([`transactions_ledger_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/transactions_ledger_screen.dart))
- **Transactions Header**: Updated main headline `Transactions` from `AppColors.white` to `AppColors.onSurface` (`#1C1B1B`).
- **Search Bar**: Fixed input text color from `AppColors.white` to `AppColors.onSurface` and tune filter icon to `AppColors.onSurface`.
- **Filter Chips**: Changed unselected filter pill text from `AppColors.white` to `AppColors.onSurface` (`#1C1B1B`) on `#F6F3F2` background.
- **Section Headers**: Changed `Today` and `Yesterday` group title labels to `AppColors.onSurface`.
- **Ledger Tiles**:
  - Replaced `amountColor: AppColors.white` with `AppColors.onSurface` for all debit transactions (`-₹120.00`, `-₹80.00`, `-₹240.00`, `-₹50.00`).
  - Updated tile title text to `AppColors.onSurface`.
  - Upgraded screen `AppBar` to standard Stitch brand header using `assets/images/brand_logo.png`, `CampusPay` title in `#1C1B1B`, and `assets/images/profile_avatar.png`.

---

### 📐 2. Universal RenderFlex Overflow Resolutions
- **[`student_home_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/student_home_screen.dart)**:
  - **Greeting Header**: Wrapped greeting text `Column` in `Expanded` and title text in `Flexible(child: Text(..., overflow: TextOverflow.ellipsis, maxLines: 1))`, preventing right-side overflow on narrow viewports.
  - **Hero Card Footer**: Wrapped token badge in `Flexible` and added `maxLines: 1, overflow: TextOverflow.ellipsis` to prevent collision with `Add Money` button.
  - **CampusCoins Banner**: Wrapped left content in `Expanded(child: Row(..., Expanded(child: Column(...))))` with `overflow: TextOverflow.ellipsis` on streak badge and redemption subtitle.
  - **Activity Tiles**: Added `maxLines: 1` and `overflow: TextOverflow.ellipsis` to titles and time strings, plus explicit spacing before the amount column.
- **[`campus_coins_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/campus_coins_screen.dart)**:
  - **Grid Aspect Ratio**: Adjusted `childAspectRatio` from `0.68` to `0.62` to guarantee sufficient vertical height for product cards across all screen scales.
  - **Card Footer**: Wrapped coins indicator in `Flexible(child: Row(..., Flexible(child: Text(..., overflow: TextOverflow.ellipsis))))` to prevent overflow when redeeming high coin counts.
- **[`scan_and_pay_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/scan_and_pay_screen.dart)**:
  - **Offline Ready Banner**: Wrapped `OFFLINE READY` row in `Expanded` with `Flexible` ellipsis on text.
  - **Camera Viewfinder**: Added `left: 16, right: 16` horizontal constraints to `Positioned` alignment instruction column and wrapped ultrasound sync message in `Flexible` with ellipsis.
  - **Recent Campus Spots**: Wrapped title row in `Flexible` with ellipsis.
- **[`enter_amount_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/enter_amount_screen.dart)**:
  - Wrapped merchant name and payment method title in `Flexible` with ellipsis.
- **[`profile_settings_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/profile_settings_screen.dart)**:
  - Wrapped 3-column metric card sublabels in `Expanded` with `maxLines: 1, overflow: TextOverflow.ellipsis`.
- **[`payment_success_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/payment_success_screen.dart)**:
  - Made receipt row values `Flexible` with `TextOverflow.ellipsis`.

---

## [v2.4.0] — 2026-09-26 (Stitch "Neon White" & Asset Ingestion)

### Summary
Migrated the entire visual identity of CampusPay from the initial Midnight dark prototype to the official **Stitch "Neon White"** design system (`projects/14706493495587560587`). Downloaded all 11 Stitch image and SVG assets locally to guarantee 100% offline rendering without external network dependencies. Resolved all static analysis lints to ensure a clean codebase.

---

### 🎨 1. Color System Migration ("Neon White")
- **Scaffold Background**: Changed default scaffold background from `#0A0A0A` to pure white `#FFFFFF` ([`AppColors.backgroundWhite`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L9)).
- **Aliasing for Legacy Screens**: Aliased [`AppColors.backgroundBlack`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L11) to `#FFFFFF` to ensure backwards compatibility across all views without layout regressions.
- **Card Surfaces**: Set elevated cards to Stitch `#F6F3F2` ([`AppColors.surfaceContainerLow`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L14)) with subtle 1px border stroke `#E5E2E1` ([`AppColors.borderStroke`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L24)).
- **High-Contrast Typography**:
  - Primary text updated to dark charcoal `#1C1B1B` ([`AppColors.onSurface`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L47)).
  - Secondary/metadata text updated to `#4B4731` ([`AppColors.onSurfaceVariant`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L48)).
  - Muted tech captions updated to `#7D775F` ([`AppColors.mutedText`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L49)).
- **Brand Hero Accents**:
  - Maintained signature ID-1 hero wallet gradient: `#6B21A8` → `#581C87` → `#4C1D95` ([`AppColors.walletHeroGradient`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L62-L66)).
  - Retained kinetic driver electric yellow `#FFE500` ([`AppColors.electricYellow`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L30)) with `#1C1B1B` text contrast.
- **Theme Definition**: Added [`AppTheme.lightTheme`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_theme.dart#L10) and set `theme: AppTheme.lightTheme` in [`main.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/main.dart#L24).

---

### 📦 2. Downloaded Assets & Pubspec Registration
Created [`assets/images/`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/) directory and registered it under `flutter: assets:` in [`pubspec.yaml`](file:///Users/manyashah/StudioProjects/CampusPay/pubspec.yaml#L69-L74). Downloaded and integrated the following 11 assets:

| File Path | Dimensions / Size | Visual Role | Screen Ingestion |
|---|---|---|---|
| [`assets/images/brand_logo.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/brand_logo.png) | 128×128 (2.4 KB) | DBIT CampusPay yellow badge emblem | Home, Settings, Coins Headers |
| [`assets/images/campuspay_logo.svg`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/campuspay_logo.svg) | Vector SVG | CampusPay geometric brand logo | Brand headers, Splash screens |
| [`assets/images/profile_avatar.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/profile_avatar.png) | 128×128 (2.4 KB) | Manya Shah student profile photo | Home header, Settings card, Scan & Pay, Receipt |
| [`assets/images/colosseum_pass.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/colosseum_pass.png) | 600×338 (80 KB) | Colosseum '26 Festival stage banner | Campus Coins featured reward card |
| [`assets/images/coffee.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/coffee.png) | 400×400 (35 KB) | Nescafe Americano cup thumbnail | Campus Coins marketplace |
| [`assets/images/samosas.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/samosas.png) | 400×400 (46 KB) | Canteen Hot Samosas basket | Campus Coins marketplace |
| [`assets/images/vip_pass.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/vip_pass.png) | 400×400 (47 KB) | Hackathon VIP pass badge | Campus Coins marketplace |
| [`assets/images/stationery.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/stationery.png) | 400×400 (42 KB) | Engineering drafting notebook | Campus Coins marketplace |
| [`assets/images/gaming.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/gaming.png) | 400×400 (54 KB) | Esports arena gaming pass | Campus Coins marketplace |
| [`assets/images/hoodie.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/hoodie.png) | 400×400 (48 KB) | DBIT Varsity collegiate hoodie | Campus Coins marketplace |
| [`assets/images/cafe_stall.png`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/cafe_stall.png) | 400×400 (54 KB) | Campus Café Counter 3 storefront | Offline Ultrasonic Payment screen |

---

### 📱 3. Screen-by-Screen Implementation Details

#### A. [`student_home_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/student_home_screen.dart)
- **Header**: Updated to render `assets/images/brand_logo.png`, `CampusPay` title in `#1C1B1B`, and `assets/images/profile_avatar.png`.
- **CampusCoins Banner**: Converted from solid dark block to Stitch light gradient (`tertiaryContainer` → `secondaryFixed` → `primaryContainer`) with `#1C1B1B` balance numerals.
- **Bento Grid**: Actions (Offline QR, Send Money, Recharge, Vault) wrapped in `#F6F3F2` cards with dark typography.
- **Protocol Badges**: Airgap status (Ultrasonic 18.4kHz, BLE Mesh, USSD Fallback) updated with clear `#1C1B1B` text.

#### B. [`campus_coins_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/campus_coins_screen.dart)
- **Featured Reward Banner**: Implemented image header displaying `assets/images/colosseum_pass.png` with gradient overlay.
- **2-Column Marketplace Grid**:
  - Replaced generic icon placeholders with actual downloaded product photos:
    - Nescafe Americano: `coffee.png`
    - Canteen Hot Samosas: `samosas.png`
    - VIP Hackathon Pass: `vip_pass.png`
    - Engineering Drafting Notebook: `stationery.png`
    - Esports Gaming Pass: `gaming.png`
    - DBIT Varsity Hoodie: `hoodie.png`
- **Redemption Dialog**: Displays selected perk image with rounded corners, dark labels, and electric yellow confirm button.

#### C. [`offline_payment_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/offline_payment_screen.dart)
- **Merchant Storefront Image**: Replaced generic cafe icon with `assets/images/cafe_stall.png` in a 44×44 rounded thumbnail.
- **Acoustic Handshake Visualizer**: Contrast improved for Piezo speaker waves and SoundBox receiver nodes.
- **Typography**: Bodoni Moda amount (`₹120.00`), protocol step labels, and transaction details rendered in high-contrast `#1C1B1B`.

#### D. [`profile_settings_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/profile_settings_screen.dart)
- **Identity Hero Card**: Replaced `MS` initials with `assets/images/profile_avatar.png` within the electric yellow verified ring.
- **Header**: Embedded `brand_logo.png` alongside campus title in `#1C1B1B`.
- **Metrics & Settings Tiles**: Wallet balance, coins count, offline limits, and navigation tiles rendered in `#F6F3F2` cards with `#1C1B1B` text.

#### E. [`scan_and_pay_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/scan_and_pay_screen.dart) & [`enter_amount_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/enter_amount_screen.dart)
- **Headers**: Styled back buttons, titles, and student avatar using `profile_avatar.png`.
- **Numeric Keypad**: Pinpad buttons (`0-9`, `.`, `backspace`) converted to `#F6F3F2` containers with `#1C1B1B` text.
- **Amount Input Zone**: Large Bodoni Moda currency display (`₹120`) and preset quick chips (`+₹50`, `+₹100`, `+₹200`, `+₹500`) updated to high-contrast dark text.

#### F. [`payment_success_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/payment_success_screen.dart)
- **Receipt Details**: Transaction ID, acoustic carrier token (`#08/10`), settlement timestamps, and merchant info styled in high contrast.
- **Header**: Added `profile_avatar.png` student avatar node.
- **Done Button**: Styled as secondary `#F6F3F2` card with dark text.

#### G. [`main_navigation_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/main_navigation_screen.dart)
- **Navigation Bar**: Pure white container `#FFFFFF` with subtle top shadow `BoxShadow(alpha: 0.05)`.
- **Floating Scan & Pay Button**: Retains `#FFE500` electric yellow kinetic glow with `#1C1B1B` icon.

#### H. [`token_vault_screen.dart`](file:///Users/manyashah/StudioProjects/CampusPay/lib/ui/screens/token_vault_screen.dart)
- **Pre-Auth Pool & Invariants**: Active token counters (`10 OF 10`), batch expiry, and 6 security invariant callout cards updated for light background readability.

---

### 🛠️ 4. Code Quality & Analysis
- **Static Analysis Result**: `flutter analyze` executed with **0 issues found**.
- **Lint Modernization**: Cleaned up Dart 3.7+ wildcard warnings (`unnecessary_underscores`) by replacing `(_, __, ___)` with `(_, _, _)`.
- **Asset Fallback Resilience**: Every `Image.asset` invocation includes an `errorBuilder` fallback that gracefully displays vector icons or initials if assets are missing.

---

## [v2.3.0] — 2026-09-24 (Offline Architecture & Ultrasonic Carrier)

### Added
- Integrated `AcousticCarrier` ultrasonic audio modulation (`18.4 kHz` FSK chirp).
- SQLite-backed ECDSA token vault with hardware security enclave simulation.
- `campuspay_architecture_poster.html` interactive visual blueprint.

---

## 📋 Quick Commands for Testing

```bash
# Run static analysis
flutter analyze

# Run locally in Chrome
flutter run -d chrome

# Run wirelessly on connected Android device
flutter run -d <DEVICE_ID>

# Hot Reload in running session
# Press 'r' in the active terminal

# Hot Restart in running session
# Press 'R' in the active terminal
```
