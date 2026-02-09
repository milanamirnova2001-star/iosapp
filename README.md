# Финансы — iOS App

Нативное iOS-приложение на SwiftUI для контроля личных финансов.

## Возможности

- **Обзор** — баланс, доходы и расходы за текущий месяц, диаграмма расходов по категориям
- **Добавление операций** — быстрое добавление доходов и расходов с выбором категории
- **История** — все операции с поиском, фильтрацией и редактированием
- **Ежемесячные платежи** — управление регулярными расходами (аренда, подписки и т.д.)
- **Статистика** — графики доходов vs расходов, расходы по дням, топ расходов
- **Настройки** — выбор валюты, экспорт/импорт данных в JSON

## Категории

### Расходы
🛒 Продукты, 🚗 Транспорт, 🏠 Жильё, 🎬 Развлечения, 💊 Здоровье, 📚 Образование, 👕 Одежда, 📱 Подписки, 💡 Коммунальные, 🍽️ Рестораны, 🥑 Бакалея, 💅 Красота, 📦 Другое

### Доходы
💰 Зарплата, 💻 Фриланс, 📈 Инвестиции, 🎁 Подарки, 📦 Другое

## Требования

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## Сборка

### Вариант 1: Codemagic (рекомендуется для Windows)

1. Создайте Git-репозиторий и запушьте этот проект
2. Подключите репозиторий в [Codemagic](https://codemagic.io)
3. Codemagic автоматически найдёт `codemagic.yaml` и запустит сборку
4. Скачайте IPA из артефактов сборки

### Вариант 2: GitHub Actions

1. Запушьте проект на GitHub
2. GitHub Actions автоматически запустит сборку
3. Перейдите в Actions → последний запуск → Artifacts → скачайте IPA

### Вариант 3: Локально (macOS)

```bash
# Установить XcodeGen
brew install xcodegen

# Сгенерировать Xcode-проект
xcodegen generate

# Открыть в Xcode
open FinanceApp.xcodeproj

# Или собрать из командной строки
xcodebuild archive \
  -project FinanceApp.xcodeproj \
  -scheme FinanceApp \
  -archivePath build/FinanceApp.xcarchive \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO
```

## Структура проекта

```
├── project.yml              # Конфигурация XcodeGen
├── codemagic.yaml           # Конфигурация Codemagic CI
├── .github/workflows/       # GitHub Actions
├── FinanceApp/
│   ├── FinanceAppApp.swift  # Точка входа приложения
│   ├── ContentView.swift    # Главный TabView
│   ├── Info.plist           # Конфигурация приложения
│   ├── Assets.xcassets/     # Ресурсы (иконки, цвета)
│   ├── Models/
│   │   ├── Transaction.swift    # Модели данных
│   │   └── DataStore.swift      # Хранилище данных
│   ├── Views/
│   │   ├── DashboardView.swift      # Главный экран
│   │   ├── AddTransactionView.swift # Добавление операции
│   │   ├── HistoryView.swift        # История операций
│   │   ├── RecurringView.swift      # Ежемесячные платежи
│   │   ├── StatsView.swift          # Статистика
│   │   └── SettingsView.swift       # Настройки
│   └── Helpers/
│       └── Extensions.swift     # Расширения и утилиты
└── README.md
```

## Хранение данных

Все данные хранятся локально на устройстве через UserDefaults. Поддерживается экспорт и импорт данных в формате JSON.

## Лицензия

MIT License
