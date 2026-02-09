import SwiftUI

struct RecurringView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddSheet = false
    @State private var editingPayment: RecurringPayment? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Total Card
                        totalCard
                        
                        // Payment List
                        if store.recurringPayments.isEmpty {
                            emptyState
                        } else {
                            paymentList
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Платежи")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddRecurringView()
            }
            .sheet(item: $editingPayment) { payment in
                EditRecurringView(payment: payment)
            }
        }
    }
    
    // MARK: - Total Card
    
    private var totalCard: some View {
        VStack(spacing: 8) {
            Text("В месяц")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
            
            Text(store.totalRecurring.asCurrency(store.currency))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.expense)
                .shadow(color: DesignSystem.expense.opacity(0.3), radius: 10)
            
            Text("\(store.recurringPayments.filter(\.isActive).count) активных")
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .modernCard()
    }
    
    // MARK: - Payment List
    
    private var paymentList: some View {
        VStack(spacing: 16) {
            ForEach(store.recurringPayments) { payment in
                paymentRow(payment)
                    .onTapGesture {
                        editingPayment = payment
                    }
            }
        }
    }
    
    private func paymentRow(_ payment: RecurringPayment) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(payment.isActive ? payment.category.color.opacity(0.1) : Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                Image(systemName: payment.category.icon)
                    .font(.title3)
                    .foregroundColor(payment.isActive ? payment.category.color : DesignSystem.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(payment.isActive ? .white : DesignSystem.textSecondary)
                HStack(spacing: 6) {
                    Text(payment.category.name)
                    Text("•")
                    Text("\(payment.dayOfMonth) числа")
                }
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(payment.amount.asCurrency(store.currency))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(payment.isActive ? .white : DesignSystem.textSecondary)
                
                // Toggle
                Button {
                    withAnimation {
                        store.toggleRecurring(payment)
                    }
                } label: {
                    Text(payment.isActive ? "Активен" : "Пауза")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(payment.isActive ? DesignSystem.income.opacity(0.2) : Color.white.opacity(0.1))
                        .foregroundColor(payment.isActive ? DesignSystem.income : DesignSystem.textSecondary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(DesignSystem.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(payment.isActive ? payment.category.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.primary.opacity(0.5))
            Text("Нет платежей")
                .font(.headline)
                .foregroundColor(.white)
            Text("Добавьте регулярные расходы: аренда, подписки, интернет")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                Text("Добавить первый платёж")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(DesignSystem.primary)
                    .cornerRadius(16)
                    .shadow(color: DesignSystem.primary.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Add Recurring View

struct AddRecurringView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var category: TransactionCategory = .housing
    @State private var dayOfMonth: Int = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                Form {
                    Section("Название") {
                        TextField("Например: Аренда", text: $name)
                    }
                    
                    Section("Сумма") {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                    }
                    
                    Section("Категория") {
                        Picker("Категория", selection: $category) {
                            ForEach(TransactionCategory.expenseCategories) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }.tag(cat)
                            }
                        }
                    }
                    
                    Section("День оплаты") {
                        Stepper("\(dayOfMonth) числа", value: $dayOfMonth, in: 1...31)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Новый платёж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") { addPayment() }
                        .bold()
                        .foregroundColor(DesignSystem.primary)
                        .disabled(name.isEmpty || amountText.isEmpty)
                }
            }
        }
    }
    
    private func addPayment() {
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanAmount), amount > 0 else { return }
        
        let payment = RecurringPayment(
            name: name,
            amount: amount,
            category: category,
            dayOfMonth: dayOfMonth
        )
        
        store.addRecurring(payment)
        dismiss()
    }
}

// MARK: - Edit Recurring View

struct EditRecurringView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    
    let payment: RecurringPayment
    
    @State private var name: String
    @State private var amountText: String
    @State private var category: TransactionCategory
    @State private var dayOfMonth: Int
    @State private var showDeleteConfirm = false
    
    init(payment: RecurringPayment) {
        self.payment = payment
        _name = State(initialValue: payment.name)
        _amountText = State(initialValue: String(format: "%.0f", payment.amount))
        _category = State(initialValue: payment.category)
        _dayOfMonth = State(initialValue: payment.dayOfMonth)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                Form {
                    Section("Название") {
                        TextField("Название", text: $name)
                    }
                    
                    Section("Сумма") {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                    }
                    
                    Section("Категория") {
                        Picker("Категория", selection: $category) {
                            ForEach(TransactionCategory.expenseCategories) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }.tag(cat)
                            }
                        }
                    }
                    
                    Section("День оплаты") {
                        Stepper("\(dayOfMonth) числа", value: $dayOfMonth, in: 1...31)
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Удалить платёж")
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
            .alert("Удалить платёж?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    store.deleteRecurring(id: payment.id)
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
    
    private func saveChanges() {
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanAmount), amount > 0 else { return }
        
        var updated = payment
        updated.name = name
        updated.amount = amount
        updated.category = category
        updated.dayOfMonth = dayOfMonth
        store.updateRecurring(updated)
        dismiss()
    }
}
