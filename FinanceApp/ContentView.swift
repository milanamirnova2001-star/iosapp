import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTab = 0
    
    init() {
        // Customize Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color(hex: "0F0F10"))
        tabBarAppearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Customize Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
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
                    Label("История", systemImage: "clock.fill")
                }
                .tag(3)
            
            RecurringView()
                .tabItem {
                    Label("Платежи", systemImage: "repeat.circle.fill")
                }
                .tag(4)
        }
        .accentColor(DesignSystem.primary)
        .preferredColorScheme(.dark)
    }
}
