# Contributing to CampusPay

Thank you for your interest in contributing to **CampusPay**! We welcome contributions from developers, designers, and researchers helping us build an ultra-resilient, offline-first payment network for university campuses.

CampusPay strictly follows the **Fork & Pull Model** to maintain code quality, preserve offline cryptographic integrity, and ensure smooth collaborative reviews.

---

## 🍴 The Fork & Pull Policy

Under the **Fork & Pull** model:
1. Contributors **do not** have direct push access to the primary repository (`upstream: ManyaShah1/CampusPay`).
2. All work is developed on your own **fork** (a personal copy of the repository under your GitHub account) and pushed to dedicated feature/bugfix branches.
3. You propose changes to the main repository by opening a **Pull Request (PR)** against `ManyaShah1/CampusPay:main`.
4. Maintainers review, suggest changes, run automated checks, and merge accepted contributions into `main`.

---

## 🛠️ Step-by-Step Contribution Workflow

### Step 1: Fork the Repository
Navigate to [CampusPay on GitHub](https://github.com/ManyaShah1/CampusPay) and click the **Fork** button (top right) to create a copy under your personal account.

### Step 2: Clone Your Fork
Clone your newly created fork to your local development machine:

```bash
git clone https://github.com/<YOUR_GITHUB_USERNAME>/CampusPay.git
cd CampusPay
```

### Step 3: Configure Upstream Remote
Configure Git to track the original repository (`upstream`) so you can easily sync future changes:

```bash
git remote add upstream https://github.com/ManyaShah1/CampusPay.git

# Verify remote configuration
git remote -v
# origin   https://github.com/<YOUR_USERNAME>/CampusPay.git (fetch & push)
# upstream https://github.com/ManyaShah1/CampusPay.git (fetch & push)
```

### Step 4: Create a Dedicated Feature Branch
**Never make commits directly on your fork's `main` branch.** Always create a descriptive branch:

```bash
# Branch naming convention:
# feature/<name>   - For new screens, methods, or components
# fix/<name>       - For bug or layout fixes
# docs/<name>      - For documentation or architecture updates
# refactor/<name>  - For code improvements or optimizations

git checkout -b feature/campus-mesh-enhancement
```

### Step 5: Implement Your Changes & Standards
While developing, adhere to the following project standards:

1. **Design System ("Neon White")**:
   - Canvas background must be `#FFFFFF` ([`AppColors.backgroundWhite`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L9)).
   - Card surfaces use `#F6F3F2` ([`AppColors.surfaceContainerLow`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L14)) with subtle border `#E5E2E1`.
   - Text colors must use high-contrast `#1C1B1B` ([`AppColors.onSurface`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L47)) or `#4B4731` ([`AppColors.onSurfaceVariant`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L48)).
   - Action accents utilize Electric Yellow `#FFE500` ([`AppColors.electricYellow`](file:///Users/manyashah/StudioProjects/CampusPay/lib/core/constants/app_colors.dart#L30)).
2. **Assets**:
   - Place all new images/SVGs in [`assets/images/`](file:///Users/manyashah/StudioProjects/CampusPay/assets/images/).
   - Always declare new asset directories in [`pubspec.yaml`](file:///Users/manyashah/StudioProjects/CampusPay/pubspec.yaml).
   - Use graceful `errorBuilder: (_, _, _) => ...` fallbacks on all `Image.asset` calls.
3. **Offline Cryptography & State**:
   - Respect ECDSA token invariants (never store unencrypted sensitive keys or private tokens).
   - State management is handled through `ChangeNotifier` and `Provider`.

### Step 6: Verify Quality (`flutter analyze`)
CampusPay maintains a zero-warning policy. Before committing, run:

```bash
flutter analyze
```

Ensure the output is:
```
No issues found!
```

### Step 7: Commit with Conventional Commits
Write concise, meaningful commit messages:

```bash
git add .
git commit -m "feat(coins): add student loyalty discount filter"
```

Prefix your commits with:
- `feat:` for new capabilities or UI screens
- `fix:` for bug and overflow fixes
- `docs:` for documentation, diagrams, or changelogs
- `style:` for styling/token alignment without logic changes
- `refactor:` for code reorganization
- `test:` for unit or widget tests

### Step 8: Sync with Upstream
Before opening a pull request, ensure your branch is up-to-date with `upstream/main` to avoid merge conflicts:

```bash
git fetch upstream
git merge upstream/main
```

### Step 9: Push to Your Fork
Push your local branch to your personal GitHub fork:

```bash
git push -u origin feature/campus-mesh-enhancement
```

### Step 10: Open a Pull Request (PR)
1. Go to [CampusPay on GitHub](https://github.com/ManyaShah1/CampusPay).
2. You will see a banner prompt: **"Compare & pull request"**. Click it.
3. Verify the base repository is `ManyaShah1/CampusPay` and base branch is `main`.
4. Fill in the Pull Request template describing the motivation, screenshots (for UI changes), and verification steps.
5. Submit the PR. Maintainers will review your submission and provide feedback.

---

## 📋 Pull Request Review Criteria

Pull Requests are evaluated on:
- [x] **Static Analysis**: Passes `flutter analyze` with 0 warnings.
- [x] **Design Fidelity**: Matches the Stitch "Neon White" design system tokens.
- [x] **Documentation**: Updates [`CHANGELOG.md`](file:///Users/manyashah/StudioProjects/CampusPay/CHANGELOG.md) under the `[Unreleased]` or next version section.
- [x] **Conflict-Free**: Cleanly merges with `upstream/main`.

---

## 📄 License
By contributing to CampusPay, you agree that your contributions will be licensed under the [MIT License](file:///Users/manyashah/StudioProjects/CampusPay/LICENSE).
