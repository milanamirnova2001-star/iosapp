import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Обзор", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            StatsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            AddTransactionView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Добавить", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("История", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)
            
            RecurringView()
                .tabItem {
                    Label("Платежи", systemImage: "repeat.circle.fill")
                }
                .tag(4)
        }
        .tint(.accentColor)
    }
}
