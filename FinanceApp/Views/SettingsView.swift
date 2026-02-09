import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showClearConfirm = false
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var exportURL: URL? = nil
    
    let currencies = ["₽", "$", "€", "₸", "₴", "£", "¥"]
    let currencyNames = ["₽ Рубль", "$ Доллар", "€ Евро", "₸ Тенге", "₴ Гривна", "£ Фунт", "¥ Йена"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Currency
                Section("Валюта") {
                    Picker("Валюта", selection: $store.currency) {
                        ForEach(Array(zip(currencies, currencyNames)), id: \.0) { symbol, name in
                            Text(name).tag(symbol)
                        }
                    }
                }
                
                // Stats
                Section("Статистика") {
                    HStack {
                        Text("Всего операций")
                        Spacer()
                        Text("\(store.transactions.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Ежемесячных платежей")
                        Spacer()
                        Text("\(store.recurringPayments.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Общий баланс")
                        Spacer()
                        Text(store.totalBalance.asCurrency(store.currency))
                            .foregroundColor(store.totalBalance >= 0 ? .incomeGreen : .expenseRed)
                            .bold()
                    }
                }
                
                // Data Management
                Section("Управление данными") {
                    Button {
                        exportData()
                    } label: {
                        Label("Экспорт данных (JSON)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Импорт данных", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Удалить все данные", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // About
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Разработчик")
                        Spacer()
                        Text("Finance App")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .bold()
                }
            }
            .alert("Удалить все данные?", isPresented: $showClearConfirm) {
                Button("Удалить", role: .destructive) {
                    store.clearAll()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все операции и ежемесячные платежи будут удалены. Это действие нельзя отменить.")
            }
            .alert("Данные импортированы!", isPresented: $showImportSuccess) {
                Button("OK") {}
            }
            .alert("Ошибка импорта", isPresented: $showImportError) {
                Button("OK") {}
            } message: {
                Text("Не удалось прочитать файл. Убедитесь, что это корректный JSON-файл экспорта.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }
    
    // MARK: - Export
    
    private func exportData() {
        guard let data = store.exportJSON() else { return }
        
        let fileName = "finance_export_\(Date().shortDateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            exportURL = tempURL
            showExportSheet = true
        } catch {
            // Handle error silently
        }
    }
    
    // MARK: - Import
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                if store.importJSON(data) {
                    showImportSuccess = true
                } else {
                    showImportError = true
                }
            } catch {
                showImportError = true
            }
            
        case .failure:
            showImportError = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
