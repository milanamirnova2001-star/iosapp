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
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                            .padding(.top, 20)
                    }
                    .padding()
                }
                .navigationTitle("Добавить")
                .overlay {
                    if showSuccess {
                        successOverlay
                    }
                }
            }
        }
    }
    
    // MARK: - Type Switcher
    
    private var typeSwitcher: some View {
        HStack(spacing: 4) {
            typeButton(type: .expense, label: "Расход")
            typeButton(type: .income, label: "Доход")
        }
        .padding(4)
        .background(DesignSystem.cardBackground)
        .cornerRadius(16)
    }
    
    private func typeButton(type: TransactionType, label: String) -> some View {
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
                .padding(.vertical, 12)
                .background(
                    transactionType == type
                    ? (type == .expense ? DesignSystem.expense : DesignSystem.income)
                    : Color.clear
                )
                .foregroundColor(transactionType == type ? .white : DesignSystem.textSecondary)
                .cornerRadius(12)
                .shadow(color: transactionType == type ? (type == .expense ? DesignSystem.expense : DesignSystem.income).opacity(0.4) : .clear, radius: 8)
        }
    }
    
    // MARK: - Amount Input
    
    private var amountInput: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $amountText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .accentColor(transactionType == .expense ? DesignSystem.expense : DesignSystem.income)
                
                Text(store.currency)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    transactionType == .expense ? DesignSystem.expense.opacity(0.3) : DesignSystem.income.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Note Field
    
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Описание")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
            
            TextField("Например: Продукты", text: $note)
                .font(.body)
                .foregroundColor(.white)
                .padding(16)
                .background(DesignSystem.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Категория")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(categories) { category in
                    categoryButton(category)
                }
            }
        }
    }
    
    private func categoryButton(_ category: TransactionCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(selectedCategory == category ? category.color : category.color.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .shadow(color: selectedCategory == category ? category.color.opacity(0.5) : .clear, radius: 8)
                    
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundColor(selectedCategory == category ? .white : category.color)
                }
                
                Text(category.name)
                    .font(.system(size: 11))
                    .foregroundColor(selectedCategory == category ? .white : DesignSystem.textSecondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Date Picker
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Дата")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .colorScheme(.dark)
                .padding(8)
                .background(DesignSystem.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button {
            addTransaction()
        } label: {
            Text("Добавить")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    (amountText.isEmpty || Double(amountText.replacingOccurrences(of: ",", with: ".")) == nil)
                    ? Color.gray.opacity(0.3)
                    : (transactionType == .expense ? DesignSystem.expense : DesignSystem.income)
                )
                .cornerRadius(18)
                .shadow(color: (transactionType == .expense ? DesignSystem.expense : DesignSystem.income).opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .disabled(amountText.isEmpty || Double(amountText.replacingOccurrences(of: ",", with: ".")) == nil)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(DesignSystem.income)
                .shadow(color: DesignSystem.income.opacity(0.5), radius: 20)
            
            Text("Успешно!")
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 20)
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
