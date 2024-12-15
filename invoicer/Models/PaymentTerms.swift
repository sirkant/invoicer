import Foundation

enum PaymentTerms: String, CaseIterable, Identifiable {
    case net10 = "Net 10"
    case net30 = "Net 30"
    case net60 = "Net 60"
    case net90 = "Net 90"
    case other = "Other"

    var id: String { self.rawValue }

    var days: Int {
        switch self {
        case .net10: return 10
        case .net30: return 30
        case .net60: return 60
        case .net90: return 90
        case .other: return 0
        }
    }
}