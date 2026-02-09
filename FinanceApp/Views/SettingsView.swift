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
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                
                Form {
                    // Currency
                    Section {
                        Picker("Валюта", selection: $store.currency) {
                            ForEach(Array(zip(currencies, currencyNames)), id: \.0) { symbol, name in
                                Text(name).tag(symbol)
                            }
                        }
                    } header: {
                        Text("Основные")
                    }
                    
                    // Stats
                    Section {
                        HStack {
                            Text("Всего операций")
                            Spacer()
                            Text("\(store.transactions.count)")
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        HStack {
                            Text("Платежей")
                            Spacer()
                            Text("\(store.recurringPayments.count)")
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        HStack {
                            Text("Баланс")
                            Spacer()
                            Text(store.totalBalance.asCurrency(store.currency))
                                .foregroundColor(store.totalBalance >= 0 ? DesignSystem.income : DesignSystem.expense)
                                .bold()
                        }
                    } header: {
                        Text("Статистика")
                    }
                    
                    // Data Management
                    Section {
                        Button {
                            exportData()
                        } label: {
                            Label("Экспорт (JSON)", systemImage: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            showImportPicker = true
                        } label: {
                            Label("Импорт (JSON)", systemImage: "square.and.arrow.down")
                                .foregroundColor(.white)
                        }
                        
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("Сбросить все данные", systemImage: "trash")
                        }
                    } header: {
                        Text("Данные")
                    }
                    
                    // About
                    Section {
                        HStack {
                            Text("Версия")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        HStack {
                            Text("Разработчик")
                            Spacer()
                            Text("Finance App")
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                    } header: {
                        Text("О приложении")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .bold()
                        .foregroundColor(DesignSystem.primary)
                }
            }
            .alert("Сброс данных", isPresented: $showClearConfirm) {
                Button("Удалить", role: .destructive) {
                    store.clearAll()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все операции и настройки будут удалены безвозвратно.")
            }
            .alert("Успешно", isPresented: $showImportSuccess) {
                Button("OK") {}
            } message: {
                Text("Данные успешно восстановлены.")
            }
            .alert("Ошибка", isPresented: $showImportError) {
                Button("OK") {}
            } message: {
                Text("Не удалось прочитать файл. Проверьте формат.")
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
        
        let fileName = "finance_backup_\(Date().shortDateString).json"
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
