import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    monthSelector
                    
                    if !store.expensesByCategory.isEmpty {
                        expenseChartCard
                    }
                    
                    if !store.recurringPayments.isEmpty {
                        recurringPreviewCard
                    }
                    
                    if !store.recentTransactions.isEmpty {
                        recentTransactionsCard
                    }
                    
                    if store.currentMonthTransactions.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Обзор")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Общий баланс")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(store.totalBalance.asCurrency(store.currency))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(store.totalBalance >= 0 ? .primary : .expenseRed)
            }
            
            Divider()
            
            HStack(spacing: 0) {
                // Income
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.incomeGreen)
                            .font(.title3)
                        Text("Доходы")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(store.monthlyIncome.asCurrency(store.currency))
                        .font(.headline)
                        .foregroundColor(.incomeGreen)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                // Expense
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.expenseRed)
                            .font(.title3)
                        Text("Расходы")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(store.monthlyExpense.asCurrency(store.currency))
                        .font(.headline)
                        .foregroundColor(.expenseRed)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation { store.changeMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            Text(store.monthYearString)
                .font(.headline)
            
            Spacer()
            
            Button {
                withAnimation { store.changeMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // MARK: - Expense Chart
    
    private var expenseChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Расходы по категориям")
                .font(.headline)
            
            Chart(store.expensesByCategory, id: \.category) { item in
                SectorMark(
                    angle: .value("Сумма", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(store.expensesByCategory, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 10, height: 10)
                        Text(item.category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(item.amount.asCurrency(store.currency))
                            .font(.caption.bold())
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Recurring Preview
    
    private var recurringPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ежемесячные платежи")
                    .font(.headline)
                Spacer()
                Text(store.totalRecurring.asCurrency(store.currency))
                    .font(.subheadline.bold())
                    .foregroundColor(.expenseRed)
            }
            
            ForEach(store.recurringPayments.filter(\.isActive).prefix(3)) { payment in
                HStack(spacing: 12) {
                    Text(payment.category.emoji)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payment.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(payment.dayOfMonth) числа")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(payment.amount.asCurrency(store.currency))
                        .font(.subheadline.bold())
                        .foregroundColor(.expenseRed)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Recent Transactions
    
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние операции")
                .font(.headline)
            
            ForEach(store.recentTransactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Нет операций за этот месяц")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Нажмите «Добавить», чтобы создать первую операцию")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    @EnvironmentObject var store: DataStore
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: transaction.category.icon)
                    .font(.body)
                    .foregroundColor(transaction.category.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.name : transaction.note)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(transaction.date.relativeDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.amount.asSignedCurrency(store.currency, type: transaction.type))
                .font(.subheadline.bold())
                .foregroundColor(transaction.type == .income ? .incomeGreen : .expenseRed)
        }
        .padding(.vertical, 2)
    }
}
