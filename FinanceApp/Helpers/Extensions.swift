import Foundation
import SwiftUI

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

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
    }
}

// MARK: - Color Extensions

extension Color {
    static let incomeGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let expenseRed = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let appBackground = Color(.systemGroupedBackground)
}

// MARK: - Array Extension for Grouping

extension Array where Element == Transaction {
    func groupedByDate() -> [(date: String, displayDate: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: self) { $0.date.sectionKey }
        return grouped.map { key, transactions in
            let displayDate = transactions.first?.date.relativeDateString ?? key
            return (date: key, displayDate: displayDate, transactions: transactions.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }
}
