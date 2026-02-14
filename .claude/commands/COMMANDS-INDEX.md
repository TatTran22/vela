# FinanceApp — AI Agent Commands Reference
## Bộ lệnh hoàn chỉnh cho Claude Code AI Agents

> **Tổng cộng: 40 commands** bao phủ toàn bộ vòng đời phát triển ứng dụng,
> từ khởi tạo project đến submission App Store.

---

## 📋 Tổng Quan

| Nhóm | Số lượng | Mục đích |
|------|----------|----------|
| Project & Workflow | 10 | init, plan, implement, review, test, PR, fix, daily, refactor, docs |
| Phase (tổng thể) | 4 | Orchestrate toàn bộ phase 1-4 |
| Feature (chi tiết) | 16 | Triển khai từng feature cụ thể |
| Infrastructure | 10 | Design system, data, AI, freemium, localization, security, performance, a11y, App Store |

---

## 🏗️ Project & Workflow Commands (10)

| Command | File | Mô tả |
|---------|------|--------|
| `/init-project` | `init-project.md` | Khởi tạo project, Swift Packages, cấu trúc thư mục, git |
| `/plan` | `plan.md` | Lập kế hoạch feature: user stories, tasks, estimates |
| `/implement` | `implement.md` | Triển khai feature theo plan (TDD) |
| `/review` | `review.md` | Code review: security, architecture, quality |
| `/test` | `test.md` | Chạy test suite, báo cáo kết quả |
| `/pr` | `pr.md` | Lint → Format → Test → Commit → Push → PR |
| `/fix-issue` | `fix-issue.md` | Sửa bug theo TDD: test first → fix |
| `/daily` | `daily.md` | Báo cáo tiến độ hàng ngày |
| `/refactor` | `refactor.md` | Cải thiện cấu trúc code |
| `/docs` | `docs.md` | Tạo/cập nhật documentation |

## 🚀 Phase Commands (4)

| Command | File | Features | Timeline |
|---------|------|----------|----------|
| `/build-phase1` | `build-phase1.md` | F1.1–F1.12 (12 features) | Tuần 1-12 |
| `/build-phase2` | `build-phase2.md` | F2.1–F2.9 (9 features) | Tuần 13-24 |
| `/build-phase3` | `build-phase3.md` | F3.1–F3.8 (8 features) | Tuần 25-36 |
| `/build-phase4` | `build-phase4.md` | F4.1–F4.10 (10 features) | Tuần 37-54 |

## 🧩 Feature Commands (16)

| Command | File | Features | Phase |
|---------|------|----------|-------|
| `/feature-accounts` | `feature-accounts.md` | F1.1 + F1.2 | 1 |
| `/feature-transactions` | `feature-transactions.md` | F1.3 + F1.4 + F1.5 | 1 |
| `/feature-categories` | `feature-categories.md` | F1.6 | 1 |
| `/feature-dashboard` | `feature-dashboard.md` | F1.7 + F1.8 | 1 |
| `/feature-onboarding` | `feature-onboarding.md` | F1.11 + F1.12 + F4.10 | 1 |
| `/feature-ecosystem` | `feature-ecosystem.md` | F1.10 + F2.8 + F2.9 | 1+2 |
| `/feature-budgets` | `feature-budgets.md` | F2.1 + F2.2 | 2 |
| `/feature-goals` | `feature-goals.md` | F2.4 | 2 |
| `/feature-recurring` | `feature-recurring.md` | F2.3 + F2.7 | 2 |
| `/feature-receipt-scan` | `feature-receipt-scan.md` | F3.1 | 3 |
| `/feature-ai-assistant` | `feature-ai-assistant.md` | F3.3 | 3 |
| `/feature-reports` | `feature-reports.md` | F3.2 + F3.7 | 3 |
| `/feature-debt-networth` | `feature-debt-networth.md` | F3.5 + F3.6 + F3.8 | 3 |
| `/feature-shared-wallet` | `feature-shared-wallet.md` | F4.1 + F4.2 | 4 |
| `/feature-rules-import` | `feature-rules-import.md` | F4.3 + F4.4 + F4.5 | 4 |
| `/feature-freelancer` | `feature-freelancer.md` | F4.6 + F4.7 | 4 |

## ⚙️ Infrastructure Commands (10)

| Command | File | Mô tả |
|---------|------|--------|
| `/design-system` | `design-system.md` | Colors, Typography, Components |
| `/data-model` | `data-model.md` | SwiftData entities, repositories |
| `/build-cloudkit` | `build-cloudkit.md` | iCloud sync, offline-first |
| `/build-ai` | `build-ai.md` | Core ML + Claude API pipeline |
| `/build-freemium` | `build-freemium.md` | StoreKit 2, paywall, subscriptions |
| `/build-localization` | `build-localization.md` | Vietnamese + English i18n |
| `/security-audit` | `security-audit.md` | Security checklist (9 categories) |
| `/performance` | `performance.md` | Performance targets & audit |
| `/accessibility` | `accessibility.md` | VoiceOver, Dynamic Type, contrast |
| `/app-store-prep` | `app-store-prep.md` | Metadata, screenshots, submission |

---

## 🗺️ Thứ Tự Thực Hiện Khuyến Nghị

```
Phase 0: Foundation
  /init-project → /design-system → /data-model all → /build-localization

Phase 1: MVP (Tuần 1-12)
  /feature-categories → /feature-accounts → /feature-transactions
  → /feature-dashboard → /build-cloudkit → /feature-ecosystem (widget)
  → /feature-onboarding → /build-freemium → /security-audit

Phase 2: Growth (Tuần 13-24)
  /feature-budgets → /feature-goals → /feature-recurring
  → /build-ai (on-device) → /feature-ecosystem (watch + siri)

Phase 3: AI & Premium (Tuần 25-36)
  /feature-receipt-scan → /feature-reports → /feature-ai-assistant
  → /feature-debt-networth → /security-audit (AI privacy)

Phase 4: Ecosystem (Tuần 37-54)
  /feature-shared-wallet → /feature-rules-import → /feature-freelancer
  → /accessibility → /performance → /app-store-prep
```

---

## 📊 Feature Coverage: 39/39 ✅

| ID | Feature | Command |
|----|---------|---------|
| F1.1 | Tạo & quản lý tài khoản | `/feature-accounts` |
| F1.2 | Multi-currency | `/feature-accounts` |
| F1.3 | Nhập giao dịch | `/feature-transactions` |
| F1.4 | List & Search | `/feature-transactions` |
| F1.5 | Transfer | `/feature-transactions` |
| F1.6 | Danh mục VN | `/feature-categories` |
| F1.7 | Dashboard | `/feature-dashboard` |
| F1.8 | Basic Reports | `/feature-dashboard` |
| F1.9 | iCloud Sync | `/build-cloudkit` |
| F1.10 | iOS Widget | `/feature-ecosystem` |
| F1.11 | Onboarding | `/feature-onboarding` |
| F1.12 | Settings | `/feature-onboarding` |
| F2.1 | Budget by Category | `/feature-budgets` |
| F2.2 | Envelope Method | `/feature-budgets` |
| F2.3 | Recurring | `/feature-recurring` |
| F2.4 | Savings Goals | `/feature-goals` |
| F2.5 | Auto-categorization | `/build-ai` |
| F2.6 | Smart Suggestion | `/build-ai` |
| F2.7 | Bill Reminders | `/feature-recurring` |
| F2.8 | Apple Watch | `/feature-ecosystem` |
| F2.9 | Siri Shortcuts | `/feature-ecosystem` |
| F3.1 | Receipt Scanning | `/feature-receipt-scan` |
| F3.2 | AI Insights | `/feature-reports` |
| F3.3 | AI Assistant | `/feature-ai-assistant` |
| F3.4 | Cash Flow Forecast | `/build-ai` |
| F3.5 | Debt Tracking | `/feature-debt-networth` |
| F3.6 | Lend/Borrow | `/feature-debt-networth` |
| F3.7 | Custom Reports | `/feature-reports` |
| F3.8 | Net Worth | `/feature-debt-networth` |
| F4.1 | Shared Wallets | `/feature-shared-wallet` |
| F4.2 | Split Bills | `/feature-shared-wallet` |
| F4.3 | Smart Rules | `/feature-rules-import` |
| F4.4 | Bank Import | `/feature-rules-import` |
| F4.5 | Auto-savings | `/feature-rules-import` |
| F4.6 | Client/Project | `/feature-freelancer` |
| F4.7 | Business/Personal | `/feature-freelancer` |
| F4.8 | macOS Full | `/build-phase4` |
| F4.9 | iPadOS | `/build-phase4` |
| F4.10 | Import Other Apps | `/feature-onboarding` |

---

*40 commands · 39 features · 7 subagents · 4 phases · 14 tháng*
*Version 1.0 — February 2026*
