---
description: "App Store submission preparation — metadata, screenshots, privacy, review guidelines, TestFlight, ASO, IAP configuration"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# App Store Submission Preparation

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` — Section 8 (Freemium) & Section 13 (Technical)
3. `docs/ARCHITECTURE.md`

---

## Preparation Checklist

### 1. App Store Connect Metadata

#### Vietnamese (Primary Language)
- [ ] **App Name** (30 chars max): Xác định tên app chính thức
- [ ] **Subtitle** (30 chars max): Mô tả ngắn gọn giá trị cốt lõi (VD: "Quản lý chi tiêu thông minh")
- [ ] **Keywords** (100 chars max): Phân tách bằng dấu phẩy, tối ưu ASO
- [ ] **Description** (4000 chars max): Bao gồm — value proposition, feature list, privacy commitment, support info
- [ ] **Promotional Text** (170 chars): Cập nhật bất cứ lúc nào không cần review
- [ ] **What's New** (Release Notes): Mô tả thay đổi theo phiên bản

#### English (Secondary Language)
- [ ] **App Name**: English version of app name
- [ ] **Subtitle**: English subtitle
- [ ] **Keywords**: English keywords (different from Vietnamese, no overlap)
- [ ] **Description**: Full English description
- [ ] **Promotional Text**: English promotional text
- [ ] **What's New**: English release notes

#### Metadata Quality Checks
- [ ] No competitor names mentioned in metadata
- [ ] No pricing information in description (use subtitle/promotional text)
- [ ] Contact/support URL included
- [ ] Marketing URL included (landing page)
- [ ] Privacy Policy URL included and accessible
- [ ] Copyright field correct (© 2026 [Company Name])

**Pass criteria:** All metadata fields completed in both Vietnamese and English, no App Review guideline violations.

### 2. Screenshots

#### Required Device Sizes
- [ ] **iPhone 6.7"** (iPhone 15 Pro Max / 16 Pro Max): 1290 × 2796 px — Required
- [ ] **iPhone 6.1"** (iPhone 15 / 16): 1179 × 2556 px — Required if different from 6.7"
- [ ] **iPad 13"** (iPad Pro 13-inch): 2064 × 2752 px — Required if iPad supported
- [ ] **Mac**: 1280 × 800 px minimum, 2560 × 1600 px recommended — Required for macOS app

#### Screenshot Content Plan (Minimum 3, Max 10 per device)
- [ ] **Screenshot 1**: Dashboard — "Tổng quan tài chính trong một cái nhìn" / "Your finances at a glance"
- [ ] **Screenshot 2**: Quick Transaction Input — "Nhập giao dịch trong 5 giây" / "Add transactions in 5 seconds"
- [ ] **Screenshot 3**: Reports & Charts — "Biểu đồ chi tiêu trực quan" / "Visual spending insights"
- [ ] **Screenshot 4**: Budget Tracking — "Kiểm soát ngân sách dễ dàng" / "Budget tracking made easy"
- [ ] **Screenshot 5**: Multi-Currency — "Đa tiền tệ, tự động quy đổi" / "Multi-currency support"
- [ ] **Screenshot 6** (optional): AI Features — "AI phân tích tài chính" / "AI-powered finance insights"
- [ ] **Screenshot 7** (optional): Widget — "Widget trên màn hình chính" / "Home screen widgets"
- [ ] **Screenshot 8** (optional): Dark Mode — App in dark mode

#### Screenshot Quality Checks
- [ ] Vietnamese screenshots cho Vietnamese locale
- [ ] English screenshots cho English locale
- [ ] Status bar shows 9:41 AM (Apple standard)
- [ ] Battery shows 100% or hidden
- [ ] No personal/real financial data visible (use demo data)
- [ ] Consistent design language across all screenshots
- [ ] Text overlays (captions) legible and contrast-compliant
- [ ] No device frames required (Apple generates them)

**Pass criteria:** All required device sizes have minimum 3 screenshots each, in both languages.

### 3. App Preview Videos (Optional but Recommended)
- [ ] **Length**: 15-30 seconds per video
- [ ] **Content**: Show core flow — open app → add transaction → view report
- [ ] **Format**: H.264 or HEVC, up to 500MB
- [ ] **Resolution**: Match device screenshot sizes
- [ ] **Audio**: Optional, background music/narration allowed
- [ ] **Localization**: Vietnamese and English versions
- [ ] **No device frames** in the video (just screen recording)
- [ ] First frame is compelling (serves as poster frame)

**Pass criteria:** At least 1 app preview video for iPhone, demonstrating core value in under 30 seconds.

### 4. App Icon
- [ ] **1024 × 1024 px** (App Store) — PNG, no transparency, no rounded corners
- [ ] Icon follows Apple HIG guidelines (no text, recognizable at small sizes)
- [ ] Icon rendered correctly at all required sizes:
  - [ ] iPhone: 60×60 pt (@2x = 120px, @3x = 180px)
  - [ ] iPad: 76×76 pt (@2x = 152px), 83.5×83.5 pt (@2x = 167px)
  - [ ] Mac: 16, 32, 64, 128, 256, 512, 1024 px
  - [ ] Apple Watch: 40×40 pt (@2x = 80px)
  - [ ] Spotlight: 40×40 pt (@2x = 80px, @3x = 120px)
  - [ ] Settings: 29×29 pt (@2x = 58px, @3x = 87px)
  - [ ] Notification: 20×20 pt (@2x = 40px, @3x = 60px)
- [ ] Asset catalog includes all required sizes
- [ ] Icon looks good on both light and dark wallpapers
- [ ] Icon is distinct from competitor apps (Money Lover, Monefy, etc.)

**Pass criteria:** Single 1024x1024 source icon provided, Asset Catalog auto-generates all sizes correctly.

### 5. Privacy Policy
- [ ] Privacy Policy URL accessible and live
- [ ] Written in both Vietnamese and English
- [ ] Covers all data collected/processed:
  - [ ] Financial data (transactions, accounts, budgets)
  - [ ] Biometric data usage (Face ID / Touch ID — on-device only)
  - [ ] Receipt images (on-device processing, optional cloud fallback)
  - [ ] Location data (optional, only when user attaches to transaction)
  - [ ] iCloud sync data (Apple's privacy policies apply)
  - [ ] Cloud AI data (aggregated only, no PII — Premium tier)
  - [ ] Analytics/crash reporting data (if applicable)
- [ ] States data is NOT sold to third parties
- [ ] States data retention and deletion policy
- [ ] Includes contact information for privacy inquiries
- [ ] GDPR-compliant (for EU users)
- [ ] Last updated date clearly shown

**Pass criteria:** Privacy policy is comprehensive, accurate, accessible, and matches actual app behavior.

### 6. App Privacy Nutrition Labels (App Store Connect)
- [ ] Declare data types collected:
  - [ ] **Financial Info**: Transaction amounts, account balances — Linked to user, Used for app functionality
  - [ ] **Purchases**: In-app purchase history — Linked to user, Used for app functionality
  - [ ] **Location**: Precise location — NOT collected by default, Optional user attachment
  - [ ] **Photos**: Receipt images — Linked to user, Used for app functionality
  - [ ] **Identifiers**: User ID (iCloud) — Linked to user, Used for app functionality
  - [ ] **Usage Data**: App interaction data — If analytics enabled
  - [ ] **Diagnostics**: Crash data, Performance data — If crash reporting enabled
- [ ] Declare data NOT collected (important for trust):
  - [ ] Contact Info: NOT collected
  - [ ] Browsing History: NOT collected
  - [ ] Search History: NOT collected (on-device only)
  - [ ] Health & Fitness: NOT collected
  - [ ] Sensitive Info: NOT collected
- [ ] Data linked to user vs not linked clearly distinguished
- [ ] Data used for tracking: NONE (no third-party ad tracking)

**Pass criteria:** Nutrition labels accurately reflect all data collection in the app.

### 7. PrivacyInfo.xcprivacy Manifest

#### Required Reason APIs Declaration
- [ ] `NSPrivacyAccessedAPITypes` declared for all APIs used:
  - [ ] **File timestamp APIs** (`NSFileCreationDate`, `NSFileModificationDate`): Reason `DDA9.1` or `C617.1`
  - [ ] **User defaults APIs** (`UserDefaults`): Reason `CA92.1` (app functionality)
  - [ ] **System boot time APIs** (if used): Declare reason
  - [ ] **Disk space APIs** (if checking available storage): Declare reason
- [ ] `NSPrivacyTracking` = `false` (no tracking)
- [ ] `NSPrivacyTrackingDomains` = empty array (no tracking domains)
- [ ] `NSPrivacyCollectedDataTypes` matches App Store nutrition labels
- [ ] PrivacyInfo.xcprivacy present in EACH target (main app, widgets, watch app, extensions)
- [ ] Third-party SDK privacy manifests included (if any SDKs used)

**Pass criteria:** `xcrun xcprivacyutil verify` passes with no errors. App Store Connect accepts upload without privacy manifest warnings.

### 8. App Review Guidelines Compliance

#### Content & Functionality
- [ ] App is complete — no "coming soon" features visible, no placeholder content
- [ ] No beta/test/debug labels in UI
- [ ] No crash on any standard user flow
- [ ] Demo account or easy onboarding so reviewer can test immediately
- [ ] App works offline (offline-first architecture)
- [ ] All IAP features accessible for review (provide sandbox test account)

#### Financial App Specific
- [ ] Disclaimer: "App chỉ hỗ trợ quản lý tài chính cá nhân, không phải tư vấn tài chính"
- [ ] No specific investment advice from AI assistant
- [ ] AI responses include disclaimer about financial advice
- [ ] No connection to real bank accounts (data entry is manual / import only)
- [ ] Currency conversion rates clearly marked as approximate

#### In-App Purchase
- [ ] Restore Purchases button accessible in Settings
- [ ] Subscription terms clearly displayed before purchase
- [ ] Free tier is fully functional (not crippled to force purchase)
- [ ] Premium features clearly marked but not overly intrusive
- [ ] Subscription auto-renewal terms displayed per Apple requirements
- [ ] Cancel subscription instructions accessible

#### Privacy
- [ ] Camera usage description string: "Chụp hóa đơn để tự động nhập giao dịch"
- [ ] Photo library usage description: "Chọn ảnh hóa đơn từ thư viện"
- [ ] Location usage description: "Thêm vị trí vào giao dịch" (optional usage)
- [ ] Face ID usage description: "Bảo vệ dữ liệu tài chính bằng Face ID"
- [ ] No unnecessary permission requests at launch (request when needed)

#### UI/UX
- [ ] No web views for core functionality (native SwiftUI)
- [ ] Standard iOS/macOS navigation patterns
- [ ] No custom rating prompts that mimic system dialogs
- [ ] `SKStoreReviewController` used for rating prompts (max 3/year)

**Pass criteria:** No App Review guideline violations that would result in rejection.

### 9. TestFlight — Release Pipeline

#### Phase 1: Internal Testing
- [ ] Internal testing group created (development team)
- [ ] Build uploaded via Xcode Cloud or manual archive
- [ ] Build passes App Store Connect processing (no errors)
- [ ] Test on all target devices:
  - [ ] iPhone (oldest supported: iPhone 15 series with iOS 17)
  - [ ] Mac (oldest supported: M1 with macOS 14)
- [ ] All core flows tested manually
- [ ] Crash-free for 48 hours
- [ ] No App Store Connect warnings

#### Phase 2: External Beta
- [ ] Beta App Review submitted and approved
- [ ] External testing group created (50-100 beta testers)
- [ ] Beta app description written (what to test, known issues)
- [ ] Feedback mechanism in place (TestFlight feedback, email, form)
- [ ] Beta test checklist distributed to testers
- [ ] Minimum 2-week external beta period
- [ ] Critical bugs from beta fixed
- [ ] Crash rate < 1% during beta
- [ ] Positive beta feedback collected (for App Store description)

#### Phase 3: Production Release
- [ ] Final build uploaded
- [ ] All metadata finalized (screenshots, description, keywords)
- [ ] App Review notes prepared (test account credentials, special instructions)
- [ ] Phased rollout enabled (start 1% → 2% → 5% → 10% → 20% → 50% → 100%)
- [ ] Crash monitoring active (Xcode Organizer, any crash reporting service)
- [ ] Support channel ready (email, website FAQ)
- [ ] Marketing website/landing page live

**Pass criteria:** App passes App Review on first submission. Phased rollout shows no critical issues.

### 10. Release Notes Template

#### Vietnamese
```
Phiên bản [X.Y.Z]

Tính năng mới:
• [Feature 1 description]
• [Feature 2 description]

Cải thiện:
• [Improvement 1]
• [Improvement 2]

Sửa lỗi:
• [Bug fix 1]
• [Bug fix 2]

Cảm ơn bạn đã sử dụng [App Name]!
Nếu bạn thích app, hãy đánh giá 5 sao trên App Store nhé ⭐
```

#### English
```
Version [X.Y.Z]

New Features:
• [Feature 1 description]
• [Feature 2 description]

Improvements:
• [Improvement 1]
• [Improvement 2]

Bug Fixes:
• [Bug fix 1]
• [Bug fix 2]

Thank you for using [App Name]!
If you enjoy the app, please leave a 5-star review on the App Store.
```

- [ ] Release notes written in both languages
- [ ] No technical jargon (user-friendly language)
- [ ] Highlights most impactful changes first
- [ ] Under 4000 characters per language

**Pass criteria:** Release notes clearly communicate value of update to end users.

### 11. ASO (App Store Optimization) Keywords Strategy

#### Vietnamese Keywords (100 chars max)
- [ ] Primary: quản lý tài chính, chi tiêu, thu nhập, ngân sách, tiết kiệm
- [ ] Secondary: sổ thu chi, quản lý tiền, ví tiền, ghi chép chi tiêu
- [ ] Long-tail: quản lý tài chính cá nhân, theo dõi chi tiêu hàng ngày
- [ ] No duplicates with app name/subtitle
- [ ] Separate by commas, no spaces after commas (maximize chars)
- [ ] Include common misspellings if applicable

#### English Keywords (100 chars max)
- [ ] Primary: finance, budget, expense, money, tracker
- [ ] Secondary: spending, savings, income, wallet, personal finance
- [ ] Long-tail: expense tracker, budget planner, money manager
- [ ] No duplicates with app name/subtitle
- [ ] Research competitor keywords (Money Lover, Monefy, YNAB)

#### ASO Ongoing Tasks
- [ ] Monitor keyword rankings weekly (App Annie, Sensor Tower, or similar)
- [ ] A/B test screenshots and subtitle (App Store Connect allows this)
- [ ] Update keywords quarterly based on search trends
- [ ] Track conversion rate (impressions → downloads)
- [ ] Respond to all App Store reviews (improves ranking)

**Pass criteria:** Keywords cover primary Vietnamese and English search terms. No wasted characters.

### 12. In-App Purchase Configuration (App Store Connect)

#### Subscription Group: "FinanceApp Premium"
- [ ] **Premium Monthly**: 49.000₫/month (~$1.99 USD equivalent)
  - [ ] Subscription group created
  - [ ] Display name (vi): "Premium Hàng Tháng"
  - [ ] Display name (en): "Premium Monthly"
  - [ ] Description of features included
  - [ ] Price tier set correctly for all territories
- [ ] **Premium Annual**: 399.000₫/year (~$19.99 USD equivalent)
  - [ ] Display name (vi): "Premium Hàng Năm"
  - [ ] Display name (en): "Premium Annual"
  - [ ] Savings badge: "Tiết kiệm 30%" / "Save 30%"
  - [ ] Price tier set correctly for all territories
- [ ] **Family Monthly**: 79.000₫/month (~$3.99 USD equivalent)
  - [ ] Family Sharing enabled
  - [ ] Display name (vi): "Gia Đình Hàng Tháng"
  - [ ] Display name (en): "Family Monthly"
- [ ] **Family Annual**: 649.000₫/year (~$34.99 USD equivalent)
  - [ ] Family Sharing enabled
  - [ ] Display name (vi): "Gia Đình Hàng Năm"
  - [ ] Display name (en): "Family Annual"

#### Subscription Configuration
- [ ] Free trial: 14 days for all subscription tiers
- [ ] Introductory offer configured (if desired)
- [ ] Promotional offer codes generated for marketing
- [ ] Subscription group level set (prevent downgrade to lower tier during active subscription)
- [ ] Grace period enabled (billing retry period)
- [ ] StoreKit 2 integration tested in sandbox
- [ ] Restore Purchases tested and working
- [ ] Subscription status correctly reflected in app UI
- [ ] Server notifications endpoint configured (if using server-side validation)

**Pass criteria:** All IAP products created, tested in sandbox, and prices correct across all territories.

### 13. Age Rating Questionnaire
- [ ] No violence: None
- [ ] No sexual content: None
- [ ] No profanity: None
- [ ] No drugs/alcohol/tobacco: None
- [ ] No gambling: None (expense tracking is NOT gambling)
- [ ] No horror/fear: None
- [ ] No mature themes: None
- [ ] Unrestricted web access: No (no web views with external links)
- [ ] Expected rating: **4+** (suitable for all ages)

**Pass criteria:** Age rating set to 4+, questionnaire accurately reflects app content.

### 14. Export Compliance (Encryption)
- [ ] App uses HTTPS (TLS): Yes — this is standard encryption
- [ ] App uses CloudKit: Yes — Apple handles encryption
- [ ] App uses SQLCipher (if applicable): Yes — declare encryption usage
- [ ] Export compliance documentation:
  - [ ] If ONLY using standard Apple frameworks (URLSession, CloudKit): Select "Yes, uses exempt encryption"
  - [ ] Exempt encryption types: standard HTTPS/TLS for data in transit
  - [ ] No custom encryption algorithms implemented
- [ ] If SQLCipher or custom encryption:
  - [ ] May need to file annual self-classification report with BIS (U.S. Bureau of Industry and Security)
  - [ ] Determine if ECCN 5D002 applies
- [ ] ITSEncryptionExportComplianceCode in Info.plist (if pre-approved)

**Pass criteria:** Export compliance questions answered correctly. No hold-up during App Review.

---

## Pre-Submission Final Checklist

- [ ] All metadata complete in both languages (vi + en)
- [ ] All screenshots uploaded for required device sizes
- [ ] App icon 1024x1024 uploaded
- [ ] Privacy Policy URL live and accessible
- [ ] App Privacy nutrition labels accurate
- [ ] PrivacyInfo.xcprivacy in all targets
- [ ] IAP products created and tested
- [ ] Age rating completed
- [ ] Export compliance answered
- [ ] App Review notes written (test credentials, special instructions)
- [ ] Build uploaded and processed without errors
- [ ] Internal TestFlight testing passed (48+ hours crash-free)
- [ ] External beta feedback addressed
- [ ] No placeholder content in app
- [ ] Release notes written
- [ ] Marketing website ready
- [ ] Support email configured
- [ ] Phased rollout plan decided

---

## Actions
For each failed check:
1. Assign to responsible team member
2. Set deadline (pre-submission blockers must be resolved before upload)
3. Verify completion
4. Re-check in App Store Connect

## Output
Generate a submission readiness report:
- Pass count / Total checks
- **Blocker** (cannot submit): Missing required metadata, screenshots, privacy policy
- **Risk** (may cause rejection): Guideline compliance issues, IAP problems
- **Enhancement** (post-launch): ASO optimization, additional screenshots, app preview videos
- Estimated submission date
- App Review expected turnaround (typically 24-48 hours)
