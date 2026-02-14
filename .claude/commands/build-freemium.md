---
description: "Triển khai Freemium model — StoreKit 2 subscription, paywall, feature gating"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Freemium & In-App Purchase

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → Tier info in each feature
3. `docs/plans/FREEMIUM-AND-KPIS.md`

## Tasks

### FinanceCore
1. `SubscriptionTier` enum: free, premium
2. `PremiumFeature` enum — all gated features:
   - unlimitedAccounts (free: max 5)
   - multiCurrency (free: 1 currency)
   - fullReportHistory (free: current month)
   - realtimeExchangeRate
   - exportData
   - customCategories (free: limited)
   - (Phase 2+: AI features, receipt scanning, etc.)
3. `SubscriptionStatus` model:
   - tier: SubscriptionTier
   - expirationDate: Date?
   - isTrialPeriod: Bool
   - productId: String?
4. `CheckPremiumAccessUseCase`:
   - isFeatureAvailable(_ feature: PremiumFeature) → Bool
   - Current tier check
5. `PurchaseSubscriptionUseCase`:
   - Initiate StoreKit 2 purchase
   - Verify transaction
   - Update local status

### StoreKit 2 Integration (Packages/FinanceData/)
6. `StoreKitManager`:
   - Product configuration (monthly, yearly)
   - `Product.products(for:)` — fetch available products
   - `product.purchase()` — initiate purchase
   - `Transaction.currentEntitlements` — check active subscriptions
   - `Transaction.updates` — listen for status changes
   - Receipt validation (App Store Server API or on-device)
7. `SubscriptionStore` — persist subscription status locally
8. Handle: restore purchases, family sharing, grace period

### FinanceUI
9. `PaywallView`:
   - Feature comparison table (Free vs Premium)
   - Price display (monthly/yearly toggle)
   - "Start Free Trial" CTA
   - "Restore Purchases" link
   - Animated feature highlights
10. `PremiumBadge`:
    - Small lock icon for gated features
    - Tap → PaywallView
11. `UpgradePrompt`:
    - Contextual prompt when hitting free limit
    - "Bạn đã dùng hết 5 tài khoản miễn phí. Nâng cấp Premium?"

### iOS
12. Present PaywallView:
    - From Settings → "Nâng cấp Premium"
    - When hitting free tier limits
    - Optional: after onboarding (soft prompt)
13. Manage subscription → deep link to App Store subscription settings

### macOS
14. PaywallView adapted for macOS window
15. Mac App Store purchase flow

### Tests
16. FeatureGating — free tier limits enforced correctly
17. PurchaseFlow — StoreKit testing configuration
18. RestorePurchase — subscription restored after reinstall
19. ExpirationHandling — expired subscription → revert to free
20. TrialPeriod — trial active, trial expired transitions
