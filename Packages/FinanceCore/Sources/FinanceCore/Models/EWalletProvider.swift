import Foundation

/// Supported e-wallet providers for digital payment accounts.
///
/// This enum represents popular e-wallet services, primarily focused on
/// Vietnamese market providers (MoMo, ZaloPay, VNPay) with an option for others.
public enum EWalletProvider: String, Sendable, CaseIterable, Codable, Hashable {
    case momo
    case zalopay
    case vnpay
    case other

    /// Localized display name for the e-wallet provider.
    ///
    /// Returns the properly capitalized name for UI display.
    public var displayName: String {
        switch self {
        case .momo: return CoreStrings.ewalletMomo
        case .zalopay: return CoreStrings.ewalletZalopay
        case .vnpay: return CoreStrings.ewalletVnpay
        case .other: return CoreStrings.ewalletOther
        }
    }

    /// SF Symbol icon name for the e-wallet provider.
    ///
    /// Returns an appropriate SF Symbol name for visual representation.
    /// Uses letter-based circle symbols for branded providers and a generic
    /// wallet icon for "other".
    public var iconName: String {
        switch self {
        case .momo: return "m.circle.fill"
        case .zalopay: return "z.circle.fill"
        case .vnpay: return "v.circle.fill"
        case .other: return "wallet.pass.fill"
        }
    }
}
