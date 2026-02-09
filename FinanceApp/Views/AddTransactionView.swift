import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedTab: Int
    
    @State private var transactionType: TransactionType = .expense
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var date: Date = Date()
    @State private var showSuccess = false
    
    private var categories: [TransactionCategory] {
        transactionType == .expense
            ? TransactionCategory.expenseCategories
            : TransactionCategory.incomeCategories
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type Switcher
                    typeSwitcher
                    
                    // Amount Input
                    amountInput
                    
                    // Note
                    noteField
                    
                    // Category Grid
                    categoryPicker
                    
                    // Date Picker
                    datePicker
                    
                    // Add Button
                    addButton
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Добавить")
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
    }
    
    // MARK: - Type Switcher
    
    private var typeSwitcher: some View {
        HStack(spacing: 0) {
            typeButton(type: .expense, label: "Расход", color: .expenseRed)
            typeButton(type: .income, label: "Доход", color: .incomeGreen)
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func typeButton(type: TransactionType, label: String, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                transactionType = type
                if type == .expense && !TransactionCategory.expenseCategories.contains(selectedCategory) {
                    selectedCategory = .food
                } else if type == .income && !TransactionCategory.incomeCategories.contains(selectedCategory) {
                    selectedCategory = .salary
                }
            }
        } label: {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(transactionType == type ? color : Color.clear)
                .foregroundColor(transactionType == type ? .white : .secondary)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Amount Input
    
    private var amountInput: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $amountText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                
                Text(store.currency)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .cardStyle()
    }
    
    // MARK: - Note Field
    
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Описание")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Например: Продукты в магазине", text: $note)
                .font(.body)
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Категория")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(categories) { category in
                    categoryButton(category)
                }
            }
        }
    }
    
    private func categoryButton(_ category: TransactionCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(selectedCategory == category ? category.color : category.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundColor(selectedCategory == category ? .white : category.color)
                }
                Text(category.name)
                    .font(.system(size: 10))
                    .foregroundColor(selectedCategory == category ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Date Picker
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Дата")
                .font(.subheadline)
                .foregroundColor(.secondary)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button {
            addTransaction()
        } label: {
            Text("Добавить операцию")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (amountText.isEmpty || Double(amountText.replacingOccurrences(of: ",", with: ".")) == nil)
                    ? Color.gray
                    : (transactionType == .expense ? Color.expenseRed : Color.incomeGreen)
                )
                .cornerRadius(14)
        }
        .disabled(amountText.isEmpty || Double(amountText.replacingOccurrences(of: ",", with: ".")) == nil)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.incomeGreen)
            Text("Операция добавлена!")
                .font(.title3.bold())
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Action
    
    private func addTransaction() {
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanAmount), amount > 0 else { return }
        
        let transaction = Transaction(
            type: transactionType,
            amount: amount,
            category: selectedCategory,
            note: note,
            date: date
        )
        
        store.addTransaction(transaction)
        
        // Show success
        withAnimation(.spring(response: 0.4)) {
            showSuccess = true
        }
        
        // Reset form
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccess = false
            }
            amountText = ""
            note = ""
            date = Date()
        }
    }
}
