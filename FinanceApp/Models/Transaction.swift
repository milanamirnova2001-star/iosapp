import Foundation
import SwiftUI

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    
    var name: String {
        switch self {
        case .income: return "Доход"
        case .expense: return "Расход"
        }
    }
}

// MARK: - Category

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    // Expense categories
    case food
    case transport
    case housing
    case entertainment
    case health
    case education
    case clothing
    case subscriptions
    case utilities
    case restaurants
    case groceries
    case beauty
    
    // Income categories
    case salary
    case freelance
    case investment
    case gift
    
    // Common
    case other
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .food: return "Продукты"
        case .transport: return "Транспорт"
        case .housing: return "Жильё"
        case .entertainment: return "Развлечения"
        case .health: return "Здоровье"
        case .education: return "Образование"
        case .clothing: return "Одежда"
        case .subscriptions: return "Подписки"
        case .utilities: return "Коммунальные"
        case .restaurants: return "Рестораны"
        case .groceries: return "Бакалея"
        case .beauty: return "Красота"
        case .salary: return "Зарплата"
        case .freelance: return "Фриланс"
        case .investment: return "Инвестиции"
        case .gift: return "Подарки"
        case .other: return "Другое"
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "cart.fill"
        case .transport: return "car.fill"
        case .housing: return "house.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .clothing: return "tshirt.fill"
        case .subscriptions: return "iphone"
        case .utilities: return "bolt.fill"
        case .restaurants: return "fork.knife"
        case .groceries: return "leaf.fill"
        case .beauty: return "sparkles"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .food: return "🛒"
        case .transport: return "🚗"
        case .housing: return "🏠"
        case .entertainment: return "🎬"
        case .health: return "💊"
        case .education: return "📚"
        case .clothing: return "👕"
        case .subscriptions: return "📱"
        case .utilities: return "💡"
        case .restaurants: return "🍽️"
        case .groceries: return "🥑"
        case .beauty: return "💅"
        case .salary: return "💰"
        case .freelance: return "💻"
        case .investment: return "📈"
        case .gift: return "🎁"
        case .other: return "📦"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .housing: return .purple
        case .entertainment: return .pink
        case .health: return .red
        case .education: return .indigo
        case .clothing: return .teal
        case .subscriptions: return .cyan
        case .utilities: return .yellow
        case .restaurants: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .groceries: return .green
        case .beauty: return Color(red: 0.95, green: 0.4, blue: 0.6)
        case .salary: return .green
        case .freelance: return .mint
        case .investment: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .gift: return .purple
        case .other: return .gray
        }
    }
    
    var isExpenseCategory: Bool {
        switch self {
        case .salary, .freelance, .investment:
            return false
        default:
            return true
        }
    }
    
    static var expenseCategories: [TransactionCategory] {
        [.food, .transport, .housing, .entertainment, .health, .education,
         .clothing, .subscriptions, .utilities, .restaurants, .groceries, .beauty, .gift, .other]
    }
    
    static var incomeCategories: [TransactionCategory] {
        [.salary, .freelance, .investment, .gift, .other]
    }
}

// MARK: - Transaction

struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    var type: TransactionType
    var amount: Double
    var category: TransactionCategory
    var note: String
    var date: Date
    
    init(
        id: UUID = UUID(),
        type: TransactionType,
        amount: Double,
        category: TransactionCategory,
        note: String = "",
        date: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recurring Payment

struct RecurringPayment: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var category: TransactionCategory
    var dayOfMonth: Int
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        category: TransactionCategory,
        dayOfMonth: Int = 1,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.dayOfMonth = dayOfMonth
        self.isActive = isActive
    }
    
    static func == (lhs: RecurringPayment, rhs: RecurringPayment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Export Data

struct ExportData: Codable {
    let transactions: [Transaction]
    let recurringPayments: [RecurringPayment]
    let currency: String
}
