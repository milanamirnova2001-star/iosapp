import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: TransactionType? = nil
    @State private var searchText: String = ""
    @State private var editingTransaction: Transaction? = nil
    
    private var filteredTransactions: [Transaction] {
        var result = store.currentMonthTransactions
        
        if let filter = filter {
            result = result.filter { $0.type == filter }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.note.localizedCaseInsensitiveContains(searchText) ||
                $0.category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var groupedTransactions: [(date: String, displayDate: String, transactions: [Transaction])] {
        filteredTransactions.groupedByDate()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month Selector
                    monthSelector
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Filter
                    filterTabs
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    
                    // Transaction List
                    if groupedTransactions.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 20) {
                                ForEach(groupedTransactions, id: \.date) { group in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(group.displayDate)
                                            .font(.subheadline.bold())
                                            .foregroundColor(DesignSystem.textSecondary)
                                            .padding(.horizontal)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(group.transactions) { transaction in
                                                Button {
                                                    editingTransaction = transaction
                                                } label: {
                                                    TransactionRow(transaction: transaction)
                                                        .padding(16)
                                                        .background(DesignSystem.cardBackground)
                                                }
                                                
                                                if transaction.id != group.transactions.last?.id {
                                                    Divider()
                                                        .background(Color.white.opacity(0.1))
                                                        .padding(.leading, 76)
                                                }
                                            }
                                        }
                                        .cornerRadius(20)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("История")
            .searchable(text: $searchText, prompt: "Поиск операций")
            .sheet(item: $editingTransaction) { transaction in
                EditTransactionView(transaction: transaction)
            }
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation { store.changeMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(DesignSystem.cardBackground))
            }
            
            Spacer()
            
            Text(store.monthYearString)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                withAnimation { store.changeMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(DesignSystem.cardBackground))
            }
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        HStack(spacing: 8) {
            filterButton(title: "Все", type: nil)
            filterButton(title: "Доходы", type: .income)
            filterButton(title: "Расходы", type: .expense)
        }
    }
    
    private func filterButton(title: String, type: TransactionType?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filter = type
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    filter == type
                    ? (type == .income ? DesignSystem.income : (type == .expense ? DesignSystem.expense : DesignSystem.primary))
                    : DesignSystem.cardBackground
                )
                .foregroundColor(filter == type ? .white : DesignSystem.textSecondary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.primary.opacity(0.5))
            Text("Операции не найдены")
                .font(.headline)
                .foregroundColor(.white)
            if !searchText.isEmpty {
                Text("Попробуйте изменить параметры поиска")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()
        }
    }
}

// MARK: - Edit Transaction View

struct EditTransactionView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    
    let transaction: Transaction
    
    @State private var amount: String
    @State private var note: String
    @State private var date: Date
    @State private var category: TransactionCategory
    @State private var showDeleteConfirm = false
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _amount = State(initialValue: String(format: "%.0f", transaction.amount))
        _note = State(initialValue: transaction.note)
        _date = State(initialValue: transaction.date)
        _category = State(initialValue: transaction.category)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                Form {
                    Section("Сумма") {
                        TextField("Сумма", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                    }
                    
                    Section("Описание") {
                        TextField("Описание", text: $note)
                    }
                    
                    Section("Категория") {
                        Picker("Категория", selection: $category) {
                            let cats = transaction.type == .expense
                                ? TransactionCategory.expenseCategories
                                : TransactionCategory.incomeCategories
                            ForEach(cats) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }.tag(cat)
                            }
                        }
                    }
                    
                    Section("Дата") {
                        DatePicker("Дата", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Удалить операцию")
                                Spacer()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") { saveChanges() }
                        .bold()
                        .foregroundColor(DesignSystem.primary)
                }
            }
            .alert("Удалить операцию?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    store.deleteTransaction(id: transaction.id)
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
    
    private func saveChanges() {
        let cleanAmount = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(cleanAmount), amountValue > 0 else { return }
        
        var updated = transaction
        updated.amount = amountValue
        updated.note = note
        updated.date = date
        updated.category = category
        store.updateTransaction(updated)
        dismiss()
    }
}
