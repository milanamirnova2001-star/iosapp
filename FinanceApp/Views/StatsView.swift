import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month Selector
                        monthSelector
                        
                        // Summary Cards
                        summaryCards
                        
                        // Income vs Expense Bar Chart
                        incomeExpenseChart
                        
                        // Top Expenses
                        if !store.topExpenses.isEmpty {
                            topExpensesCard
                        }
                        
                        // Daily Spending Chart
                        if store.monthlyExpense > 0 {
                            dailySpendingChart
                        }
                        
                        // Category Breakdown
                        if !store.expensesByCategory.isEmpty {
                            categoryBreakdown
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Статистика")
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
        .padding(.vertical, 4)
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Доходы",
                amount: store.monthlyIncome,
                color: DesignSystem.income,
                icon: "arrow.up.right"
            )
            summaryCard(
                title: "Расходы",
                amount: store.monthlyExpense,
                color: DesignSystem.expense,
                icon: "arrow.down.left"
            )
        }
    }
    
    private func summaryCard(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(amount.asCurrency(store.currency))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(DesignSystem.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Income vs Expense Chart
    
    private var incomeExpenseChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Баланс")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                BarMark(
                    x: .value("Тип", "Доход"),
                    y: .value("Сумма", store.monthlyIncome)
                )
                .foregroundStyle(DesignSystem.income.gradient)
                .cornerRadius(8)
                
                BarMark(
                    x: .value("Тип", "Расход"),
                    y: .value("Сумма", store.monthlyExpense)
                )
                .foregroundStyle(DesignSystem.expense.gradient)
                .cornerRadius(8)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel() {
                        if let val = value.as(Double.self) {
                            Text(formatShort(val))
                                .font(.caption2)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Top Expenses
    
    private var topExpensesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Топ расходов")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(Array(store.topExpenses.enumerated()), id: \.element.id) { index, transaction in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(width: 20)
                    
                    ZStack {
                        Circle()
                            .fill(transaction.category.color.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: transaction.category.icon)
                            .font(.caption)
                            .foregroundColor(transaction.category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.note.isEmpty ? transaction.category.name : transaction.note)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(transaction.date.shortDateString)
                            .font(.caption)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(transaction.amount.asCurrency(store.currency))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                
                if index < store.topExpenses.count - 1 {
                    Divider().background(Color.white.opacity(0.1))
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Daily Spending Chart
    
    private var dailySpendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Динамика расходов")
                .font(.headline)
                .foregroundColor(.white)
            
            let dailyData = store.dailyExpenses
            let avgDaily = store.monthlyExpense / Double(max(dailyData.count, 1))
            
            Chart {
                ForEach(dailyData, id: \.day) { item in
                    BarMark(
                        x: .value("День", item.day),
                        y: .value("Сумма", item.amount)
                    )
                    .foregroundStyle(
                        item.amount > avgDaily * 1.5
                        ? DesignSystem.expense.gradient
                        : DesignSystem.primary.gradient
                    )
                    .cornerRadius(2)
                }
                
                RuleMark(y: .value("Среднее", avgDaily))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisValueLabel().foregroundStyle(DesignSystem.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("По категориям")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(store.expensesByCategory, id: \.category) { item in
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundColor(item.category.color)
                            .frame(width: 20)
                        Text(item.category.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(item.amount.asCurrency(store.currency))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.color)
                                .frame(width: geo.size.width * barFraction(item.amount), height: 6)
                                .neonGlow(item.category.color)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(20)
        .modernCard()
    }
    
    // MARK: - Helpers
    
    private func formatShort(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fМ", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fК", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
    
    private func barFraction(_ amount: Double) -> CGFloat {
        guard let maxAmount = store.expensesByCategory.first?.amount, maxAmount > 0 else { return 0 }
        return CGFloat(amount / maxAmount)
    }
}
