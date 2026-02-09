import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Balance
                        balanceCard
                        
                        // Stats Row
                        statsRow
                        
                        // Chart
                        if !store.expensesByCategory.isEmpty {
                            expenseChartCard
                        }
                        
                        // Lists
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
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Обзор")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(store.monthYearString)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    withAnimation { store.changeMonth(by: -1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(DesignSystem.cardBackground))
                }
                
                Button {
                    withAnimation { store.changeMonth(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(DesignSystem.cardBackground))
                }
                
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(DesignSystem.cardBackground))
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hex: "2E2E3A"), Color(hex: "1C1C1E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                Text("Общий баланс")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(store.totalBalance.asCurrency(store.currency))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                
                HStack {
                    Spacer()
                    // Decorator
                    Circle()
                        .stroke(DesignSystem.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .offset(x: 30, y: 30)
                        .blur(radius: 5)
                }
            }
            .padding(24)
        }
        .cornerRadius(DesignSystem.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 16) {
            statBubble(
                title: "Доходы",
                amount: store.monthlyIncome,
                color: DesignSystem.income,
                icon: "arrow.up.right"
            )
            
            statBubble(
                title: "Расходы",
                amount: store.monthlyExpense,
                color: DesignSystem.expense,
                icon: "arrow.down.left"
            )
        }
    }
    
    private func statBubble(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(amount.asCurrency(store.currency))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
        .padding(16)
        .background(DesignSystem.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Expense Chart
    
    private var expenseChartCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Расходы")
                .font(.headline)
                .foregroundColor(.white)
            
            if #available(iOS 17.0, *) {
                Chart(store.expensesByCategory, id: \.category) { item in
                    SectorMark(
                        angle: .value("Сумма", item.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(item.category.color)
                    .shadow(color: item.category.color.opacity(0.3), radius: 5)
                }
                .frame(height: 220)
                .chartBackground { proxy in
                    GeometryReader { geo in
                        if let plotFrame = proxy.plotFrame {
                            let frame = geo[plotFrame]
                            VStack(spacing: 4) {
                                Text("Всего")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.textSecondary)
                                Text(store.monthlyExpense.asCurrency(store.currency))
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            } else {
                Chart(store.expensesByCategory, id: \.category) { item in
                    BarMark(
                        x: .value("Категория", item.category.name),
                        y: .value("Сумма", item.amount)
                    )
                    .foregroundStyle(item.category.color)
                }
                .frame(height: 200)
            }
            
            // Modern Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.expensesByCategory, id: \.category) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 8, height: 8)
                                .shadow(color: item.category.color.opacity(0.5), radius: 4)
                            Text(item.category.name)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                            Text(item.amount.asCurrency(store.currency))
                                .font(.caption)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DesignSystem.cardBackground.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(item.category.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Recurring Preview
    
    private var recurringPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Платежи")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(store.totalRecurring.asCurrency(store.currency))
                    .font(.subheadline.bold())
                    .foregroundColor(DesignSystem.expense)
            }
            
            ForEach(store.recurringPayments.filter(\.isActive).prefix(3)) { payment in
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(payment.category.color.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: payment.category.icon)
                            .foregroundColor(payment.category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(payment.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(payment.dayOfMonth) числа")
                            .font(.caption)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(payment.amount.asCurrency(store.currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Recent Transactions
    
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Последние")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(store.recentTransactions) { transaction in
                TransactionRow(transaction: transaction)
                if transaction.id != store.recentTransactions.last?.id {
                    Divider().background(Color.white.opacity(0.1))
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.primary.opacity(0.5))
            Text("Нет операций")
                .font(.headline)
                .foregroundColor(.white)
            Text("Добавьте первую операцию, чтобы увидеть статистику")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    @EnvironmentObject var store: DataStore
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.category.icon)
                    .foregroundColor(transaction.category.color)
                    .font(.system(size: 18))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note.isEmpty ? transaction.category.name : transaction.note)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(transaction.date.relativeDateString)
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.amount.asSignedCurrency(store.currency, type: transaction.type))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(transaction.type == .income ? DesignSystem.income : .white)
        }
    }
}
