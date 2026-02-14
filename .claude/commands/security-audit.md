---
description: "Security audit checklist — 9 categories: data, auth, network, keychain, privacy, code, CloudKit, payments, app"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Security Audit

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/ARCHITECTURE.md`
3. `docs/CONVENTIONS.md`

## Audit Checklist

### 1. Data Security
- [ ] No sensitive data in UserDefaults (use Keychain)
- [ ] No hardcoded API keys or secrets in source code
- [ ] SwiftData encryption at rest (NSPersistentStoreDescription encryption)
- [ ] Receipt images stored securely
- [ ] Export files cleaned up after sharing

### 2. Authentication & Biometrics
- [ ] Face ID / Touch ID via LocalAuthentication framework
- [ ] Biometric evaluation handles all error cases
- [ ] Auto-lock timeout implemented correctly
- [ ] No bypass of biometric check on app backgrounding
- [ ] Passcode fallback handled securely

### 3. Network Security
- [ ] HTTPS only (no HTTP exceptions in Info.plist ATS)
- [ ] Certificate pinning for exchange rate API (if applicable)
- [ ] No sensitive data in URL parameters
- [ ] API responses validated before processing

### 4. Keychain Usage
- [ ] Subscription receipt stored in Keychain
- [ ] Any API tokens in Keychain (not UserDefaults)
- [ ] Keychain access group for app + widget sharing
- [ ] kSecAttrAccessibleAfterFirstUnlock for sync data

### 5. Privacy
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) present
- [ ] Required reason APIs declared
- [ ] No unnecessary location tracking
- [ ] Location data optional and clearly explained
- [ ] No analytics without consent
- [ ] GDPR-compliant data export

### 6. Code Security
- [ ] No force unwraps (`!`) except IBOutlet
- [ ] Input validation on all user inputs (amounts, names)
- [ ] No SQL injection (SwiftData uses parameterized queries)
- [ ] No XSS in any WebView (if used)
- [ ] Decimal type for all monetary values (no Float/Double)

### 7. CloudKit Security
- [ ] Private database only (no public database)
- [ ] User data isolated per iCloud account
- [ ] No sensitive data in CloudKit metadata
- [ ] Sync conflict resolution doesn't lose data

### 8. In-App Purchase Security
- [ ] StoreKit 2 on-device verification
- [ ] Server-side receipt validation (if applicable)
- [ ] No client-side premium feature unlocking bypass
- [ ] Subscription status cached but verified periodically

### 9. App Security
- [ ] No debug logs in Release builds
- [ ] No test/sample data shipped in production
- [ ] Minimum deployment targets (iOS 17, macOS 14) for latest security
- [ ] App Transport Security enabled
- [ ] Scene lifecycle handles sensitive data on backgrounding

## Actions
For each failed check:
1. Create a fix task with priority
2. Implement fix
3. Re-verify
4. Document in security log

## Output
Generate a security report:
- Pass count / Total checks
- Critical issues (must fix before release)
- Warnings (should fix)
- Recommendations (nice to have)
