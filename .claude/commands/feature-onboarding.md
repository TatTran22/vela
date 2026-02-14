---
description: "Triển khai feature Onboarding — F1.11 First-run experience + F1.12 Settings + F4.10 Import Other Apps"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Onboarding & Settings

## Feature Spec References
- F1.11: Onboarding Flow
- F1.12: Settings
- F4.10: Import từ app khác (Phase 4, placeholder only)

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.11, F1.12
3. `docs/DATA-MODEL.md`
4. `docs/DESIGN-SYSTEM.md`

## Tasks

### FinanceCore
1. `AppSettings` model (persisted via UserDefaults / @AppStorage):
   - primaryCurrency: CurrencyCode (default: detect locale → VND)
   - theme: AppTheme (dark, light, system)
   - language: AppLanguage (vi, en)
   - monthStartDay: Int (default: 1, range 1-28)
   - isBiometricEnabled: Bool
   - autoLockTimeout: AutoLockTimeout (immediate, 1min, 5min, never)
   - hasCompletedOnboarding: Bool
   - lastSyncDate: Date?
2. `AppTheme` enum: dark, light, system
3. `AppLanguage` enum: vi, en
4. `AutoLockTimeout` enum: immediate, oneMinute, fiveMinutes, never
5. `OnboardingStep` enum: currency, createAccount, initialBalance, trialTransaction, highlights
6. `CompleteOnboardingUseCase`:
   - Mark onboarding complete
   - Seed default categories (locale-aware)
   - Create first account with initial balance
7. `UpdateSettingsUseCase`:
   - Validate monthStartDay (1-28)
   - Theme change → update app appearance
   - Language change → update localization
8. `ExportDataUseCase`:
   - Export all transactions to CSV
   - Export all data to JSON (full backup)
   - Include metadata: app version, export date, account info
9. `BiometricAuthUseCase`:
   - Check availability (Face ID / Touch ID)
   - Authenticate
   - Enable/disable
10. `ImportDataUseCase` (Phase 4 placeholder):
    - Parse CSV from Money Lover, MISA, Spendy
    - Map categories, accounts
    - Preview before import

### FinanceData
11. `SettingsStore` — UserDefaults wrapper with @AppStorage
12. `DataExporter`:
    - toCSV(transactions: [Transaction]) → String
    - toJSON(data: AppBackup) → Data
13. `AppBackup` model — accounts + categories + transactions + settings

### FinanceUI
14. `OnboardingPageView` — reusable page with illustration + title + subtitle
15. `CurrencySelectionView` — grid of currencies, auto-detect highlighted
16. `FeatureHighlightCard` — icon + title + description slide

### iOS
17. `OnboardingFlow` — PageTabView / custom stepper:
    - Step 1: `CurrencySelectionView` — detect locale → highlight VND, cannot skip
    - Step 2: `CreateFirstAccountView` — name, type, icon (pre-filled "Ví tiền mặt")
    - Step 3: `InitialBalanceView` — enter current balance (skippable)
    - Step 4: `TrialTransactionView` — guided first transaction entry (skippable)
    - Step 5: `FeatureHighlightsView` — 3 slides showing key features (skippable)
    - Progress indicator (dots or step bar)
    - Target: < 2 minutes total
18. `SettingsView`:
    - Section: Giao diện — Theme picker, App icon (if alternatives)
    - Section: Đồng tiền — Primary currency, format preview
    - Section: Ngôn ngữ — Language picker (vi/en)
    - Section: Ngày bắt đầu tháng — Picker 1-28 with explanation
    - Section: Bảo mật — Face ID/Touch ID toggle, Auto-lock timeout
    - Section: Dữ liệu — Export CSV, Export JSON, iCloud sync status
    - Section: Import (Phase 4) — "Nhập từ app khác" → placeholder screen
    - Section: Về ứng dụng — Version, licenses, support link
19. `BiometricLockView`:
    - Show on app launch if enabled
    - Face ID / Touch ID prompt
    - Passcode fallback

### macOS
20. Settings window (macOS Preferences style):
    - General tab: Theme, Language, Month start day
    - Currency tab: Primary currency, format settings
    - Security tab: Touch ID, auto-lock
    - Data tab: Export, Import, Sync status
    - About tab
21. Onboarding as sheet on first launch (simplified, 3 steps)

### Tests
22. OnboardingFlow — complete all steps, skip optional steps
23. Settings — persist and restore all settings
24. CurrencyDetection — vi locale → VND, en_US → USD
25. ExportCSV — valid format, all fields, Vietnamese characters
26. ExportJSON — valid JSON, can re-import
27. BiometricAuth — enable/disable, fallback behavior
28. MonthStartDay — boundary: day 28, day 1, affect report periods
