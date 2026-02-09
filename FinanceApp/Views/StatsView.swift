import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
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
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Доходы",
                amount: store.monthlyIncome,
                color: .incomeGreen,
                icon: "arrow.up.circle.fill"
            )
            summaryCard(
                title: "Расходы",
                amount: store.monthlyExpense,
                color: .expenseRed,
                icon: "arrow.down.circle.fill"
            )
            summaryCard(
                title: "Баланс",
                amount: store.monthlyBalance,
                color: store.monthlyBalance >= 0 ? .incomeGreen : .expenseRed,
                icon: "equal.circle.fill"
            )
        }
    }
    
    private func summaryCard(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(amount.asCurrency(store.currency))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
    
    // MARK: - Income vs Expense Chart
    
    private var incomeExpenseChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Доходы vs Расходы")
                .font(.headline)
            
            Chart {
                BarMark(
                    x: .value("Тип", "Доходы"),
                    y: .value("Сумма", store.monthlyIncome)
                )
                .foregroundStyle(Color.incomeGreen.gradient)
                .cornerRadius(8)
                
                BarMark(
                    x: .value("Тип", "Расходы"),
                    y: .value("Сумма", store.monthlyExpense)
                )
                .foregroundStyle(Color.expenseRed.gradient)
                .cornerRadius(8)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatShort(val))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Top Expenses
    
    private var topExpensesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Топ расходов")
                .font(.headline)
            
            ForEach(Array(store.topExpenses.enumerated()), id: \.element.id) { index, transaction in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    ZStack {
                        Circle()
                            .fill(transaction.category.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: transaction.category.icon)
                            .font(.caption)
                            .foregroundColor(transaction.category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.note.isEmpty ? transaction.category.name : transaction.note)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(transaction.date.shortDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(transaction.amount.asCurrency(store.currency))
                        .font(.subheadline.bold())
                        .foregroundColor(.expenseRed)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Daily Spending Chart
    
    private var dailySpendingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Расходы по дням")
                .font(.headline)
            
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
                        ? Color.expenseRed.gradient
                        : Color.accentColor.gradient
                    )
                    .cornerRadius(2)
                }
                
                RuleMark(y: .value("Среднее", avgDaily))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Среднее")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatShort(val))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("По категориям")
                .font(.headline)
            
            ForEach(store.expensesByCategory, id: \.category) { item in
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundColor(item.category.color)
                            .frame(width: 20)
                        Text(item.category.name)
                            .font(.subheadline)
                        Spacer()
                        Text(item.amount.asCurrency(store.currency))
                            .font(.subheadline.bold())
                        Text(percentString(item.amount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.color)
                                .frame(width: geo.size.width * barFraction(item.amount), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .cardStyle()
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
    
    private func percentString(_ amount: Double) -> String {
        guard store.monthlyExpense > 0 else { return "0%" }
        let percent = (amount / store.monthlyExpense) * 100
        return String(format: "%.0f%%", percent)
    }
    
    private func barFraction(_ amount: Double) -> CGFloat {
        guard let maxAmount = store.expensesByCategory.first?.amount, maxAmount > 0 else { return 0 }
        return CGFloat(amount / maxAmount)
    }
}
