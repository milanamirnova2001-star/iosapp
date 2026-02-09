import SwiftUI

// MARK: - Design System

struct DesignSystem {
    static let background = Color(hex: "050505") // Почти черный
    static let cardBackground = Color(hex: "151517") // Темно-серый для карточек
    static let primary = Color(hex: "6C63FF") // Фиолетовый акцент
    static let income = Color(hex: "00E676") // Неоновый зеленый
    static let expense = Color(hex: "FF3D57") // Неоновый красный
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    
    static let cornerRadius: CGFloat = 24
}

// MARK: - Date Extensions

extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: self).capitalized
    }
    
    var dayMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: self)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: self)
    }
    
    var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var relativeDateString: String {
        if isToday { return "Сегодня" }
        if isYesterday { return "Вчера" }
        return dayMonthString
    }
    
    var sectionKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

// MARK: - Double Extensions

extension Double {
    func asCurrency(_ currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: abs(self))) ?? "0"
        
        if self < 0 {
            return "-\(formatted) \(currency)"
        }
        return "\(formatted) \(currency)"
    }
    
    func asSignedCurrency(_ currency: String, type: TransactionType) -> String {
        let prefix = type == .income ? "+" : "-"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "0"
        return "\(prefix)\(formatted) \(currency)"
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct ModernCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.cardBackground)
            .cornerRadius(DesignSystem.cornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct NeonGlow: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
    }
}

extension View {
    func modernCard() -> some View {
        self.modifier(ModernCard())
    }
    
    func neonGlow(_ color: Color) -> some View {
        self.modifier(NeonGlow(color: color))
    }
    
    func appBackground() -> some View {
        self.background(DesignSystem.background.ignoresSafeArea())
    }
}

// MARK: - Grouping

extension Array where Element == Transaction {
    func groupedByDate() -> [(date: String, displayDate: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: self) { $0.date.sectionKey }
        return grouped.map { key, transactions in
            let displayDate = transactions.first?.date.relativeDateString ?? key
            return (date: key, displayDate: displayDate, transactions: transactions.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }
}
