import Foundation
import SwiftUI

class DataStore: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var transactions: [Transaction] = []
    @Published var recurringPayments: [RecurringPayment] = []
    @Published var currency: String = "₽"
    @Published var selectedMonth: Date = Date()
    
    // MARK: - Storage Keys
    
    private let transactionsKey = "finance_transactions"
    private let recurringKey = "finance_recurring"
    private let currencyKey = "finance_currency"
    
    // MARK: - Init
    
    init() {
        load()
    }
    
    // MARK: - Computed Properties — Current Month
    
    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }.sorted { $0.date > $1.date }
    }
    
    var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyExpense: Double {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyBalance: Double {
        monthlyIncome - monthlyExpense
    }
    
    var totalBalance: Double {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return income - expense
    }
    
    var totalRecurring: Double {
        recurringPayments
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Categories Breakdown
    
    var expensesByCategory: [(category: TransactionCategory, amount: Double)] {
        var dict: [TransactionCategory: Double] = [:]
        for t in currentMonthTransactions where t.type == .expense {
            dict[t.category, default: 0] += t.amount
        }
        return dict.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var incomeByCategory: [(category: TransactionCategory, amount: Double)] {
        var dict: [TransactionCategory: Double] = [:]
        for t in currentMonthTransactions where t.type == .income {
            dict[t.category, default: 0] += t.amount
        }
        return dict.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Daily Spending
    
    var dailyExpenses: [(day: Int, amount: Double)] {
        let calendar = Calendar.current
        var dict: [Int: Double] = [:]
        for t in currentMonthTransactions where t.type == .expense {
            let day = calendar.component(.day, from: t.date)
            dict[day, default: 0] += t.amount
        }
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        return (1...daysInMonth).map { (day: $0, amount: dict[$0] ?? 0) }
    }
    
    // MARK: - Recent
    
    var recentTransactions: [Transaction] {
        Array(currentMonthTransactions.prefix(5))
    }
    
    // MARK: - Top Expenses
    
    var topExpenses: [Transaction] {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Month Navigation
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    var monthYearString: String {
        selectedMonth.monthYearString
    }
    
    // MARK: - Transaction CRUD
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        save()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            save()
        }
    }
    
    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        save()
    }
    
    func deleteTransactions(at offsets: IndexSet, from list: [Transaction]) {
        let idsToDelete = offsets.map { list[$0].id }
        transactions.removeAll { idsToDelete.contains($0.id) }
        save()
    }
    
    // MARK: - Recurring CRUD
    
    func addRecurring(_ payment: RecurringPayment) {
        recurringPayments.append(payment)
        save()
    }
    
    func deleteRecurring(id: UUID) {
        recurringPayments.removeAll { $0.id == id }
        save()
    }
    
    func toggleRecurring(_ payment: RecurringPayment) {
        if let index = recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringPayments[index].isActive.toggle()
            save()
        }
    }
    
    func updateRecurring(_ payment: RecurringPayment) {
        if let index = recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringPayments[index] = payment
            save()
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(transactions) {
            UserDefaults.standard.set(data, forKey: transactionsKey)
        }
        if let data = try? encoder.encode(recurringPayments) {
            UserDefaults.standard.set(data, forKey: recurringKey)
        }
        UserDefaults.standard.set(currency, forKey: currencyKey)
    }
    
    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? decoder.decode([Transaction].self, from: data) {
            transactions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let decoded = try? decoder.decode([RecurringPayment].self, from: data) {
            recurringPayments = decoded
        }
        if let c = UserDefaults.standard.string(forKey: currencyKey) {
            currency = c
        }
    }
    
    // MARK: - Export / Import
    
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let export = ExportData(
            transactions: transactions,
            recurringPayments: recurringPayments,
            currency: currency
        )
        return try? encoder.encode(export)
    }
    
    func importJSON(_ data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode(ExportData.self, from: data) {
            transactions = decoded.transactions
            recurringPayments = decoded.recurringPayments
            currency = decoded.currency
            save()
            return true
        }
        return false
    }
    
    func clearAll() {
        transactions = []
        recurringPayments = []
        save()
    }
}
