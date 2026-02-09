import SwiftUI

struct RecurringView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddSheet = false
    @State private var editingPayment: RecurringPayment? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Ежемесячные")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
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
            Text("Ежемесячные расходы")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(store.totalRecurring.asCurrency(store.currency))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.expenseRed)
            Text("\(store.recurringPayments.filter(\.isActive).count) активных платежей")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
    
    // MARK: - Payment List
    
    private var paymentList: some View {
        VStack(spacing: 8) {
            ForEach(store.recurringPayments) { payment in
                paymentRow(payment)
                    .onTapGesture {
                        editingPayment = payment
                    }
            }
        }
    }
    
    private func paymentRow(_ payment: RecurringPayment) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(payment.isActive ? payment.category.color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 46, height: 46)
                Image(systemName: payment.category.icon)
                    .font(.body)
                    .foregroundColor(payment.isActive ? payment.category.color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(payment.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(payment.isActive ? .primary : .secondary)
                HStack(spacing: 4) {
                    Text(payment.category.name)
                    Text("•")
                    Text("\(payment.dayOfMonth) числа")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.amount.asCurrency(store.currency))
                    .font(.subheadline.bold())
                    .foregroundColor(payment.isActive ? .expenseRed : .secondary)
                
                // Toggle
                Button {
                    withAnimation {
                        store.toggleRecurring(payment)
                    }
                } label: {
                    Text(payment.isActive ? "Активен" : "Выключен")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(payment.isActive ? Color.incomeGreen.opacity(0.15) : Color.gray.opacity(0.1))
                        .foregroundColor(payment.isActive ? .incomeGreen : .gray)
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteRecurring(id: payment.id)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Нет ежемесячных платежей")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Добавьте регулярные расходы: аренда, подписки, коммунальные услуги")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                Label("Добавить платёж", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
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
            Form {
                Section("Название") {
                    TextField("Например: Аренда квартиры", text: $name)
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
                    Stepper("\(dayOfMonth) числа каждого месяца", value: $dayOfMonth, in: 1...31)
                }
            }
            .navigationTitle("Новый платёж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") { addPayment() }
                        .bold()
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
                    Stepper("\(dayOfMonth) числа каждого месяца", value: $dayOfMonth, in: 1...31)
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
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") { saveChanges() }
                        .bold()
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
