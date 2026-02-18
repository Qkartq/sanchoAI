# AI Companion

<div align="center">

![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square)
![Flet](https://img.shields.io/badge/Flet-0.21+-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows/Android-green?style=flat-square)

A local AI companion app that works offline, built with Python and Flet.

[English](#english) | [Русский](#русский)

---

</div>

<a name="english"></a>

## English

### Features

- **Chat with AI** - Conversational AI powered by local GGUF models
- **Smart Context Management** - Automatic summarization when context limit is reached
- **Status Bar** - Real-time AI model status (loading, ready, generating)
- **Theme Support** - Light, Dark, and System theme modes (Material 3)
- **Multilingual** - Russian and English interface
- **History** - Persistent chat history with SQLite
- **Customizable** - Configure AI personality via system prompt
- **Modern UI** - Material Design 3 with clean interface

### Requirements

- Python 3.10+
- 4GB+ RAM (6GB+ recommended)
- Windows 10+ or Android 8.0+
- GGUF model file (included)

### Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the app:
```bash
python main.py
```

### Building APK

Prerequisites: Flutter SDK must be installed.

```bash
flet build apk sanchoAI --project AICompanion --org com.aicompanion
```

### Project Structure

```
sanchoAI/
├── app/
│   ├── main.py              # App entry point
│   ├── screens/             # UI screens
│   │   ├── chat.py          # Main chat screen
│   │   └── settings.py      # Settings screen
│   ├── services/            # Business logic
│   │   ├── ai_service.py   # AI model inference
│   │   ├── db_service.py   # SQLite database
│   │   └── notification_service.py
│   ├── widgets/             # Reusable UI components
│   │   ├── message_bubble.py
│   │   └── status_bar.py   # AI status indicator
│   ├── models/              # Data models
│   ├── i18n/                # Internationalization
│   └── utils/               # Utilities
├── google_gemma-3-1b-it-Q5_K_M.gguf  # AI Model
├── requirements.txt
└── main.py
```

### Configuration

- **AI Model**: Uses Gemma 3B GGUF model (Q5_K_M quantization)
- **Database**: SQLite stored in app data folder
- **Theme**: System/Light/Dark via settings
- **Language**: Auto-detected or manual in settings
- **Context Limit**: 1024 tokens (automatic summarization on overflow)

### License

MIT License - See LICENSE file for details.

---

<a name="русский"></a>

## Русский

### Функции

- **Чат с AI** - Разговорный AI на основе локальной GGUF модели
- **Умное управление контекстом** - Автоматическое создание резюме при превышении лимита
- **Статус бар** - Отображение состояния AI модели в реальном времени
- **Темы** - Светлая, тёмная и системная темы (Material 3)
- **Многоязычность** - Русский и английский интерфейс
- **История** - Сохранение истории чата в SQLite
- **Настройка** - Изменение личности AI через system prompt
- **Современный UI** - Material Design 3 с чистым интерфейсом

### Требования

- Python 3.10+
- 4GB+ RAM (рекомендуется 6GB+)
- Windows 10+ или Android 8.0+
- GGUF файл модели (включён)

### Установка

1. Установите зависимости:
```bash
pip install -r requirements.txt
```

2. Запустите приложение:
```bash
python main.py
```

### Сборка APK

Требование: Flutter SDK должен быть установлен.

```bash
flet build apk sanchoAI --project AICompanion --org com.aicompanion
```

### Структура проекта

```
sanchoAI/
├── app/
│   ├── main.py              # Точка входа
│   ├── screens/             # Экраны UI
│   │   ├── chat.py         # Экран чата
│   │   └── settings.py     # Настройки
│   ├── services/           # Бизнес-логика
│   │   ├── ai_service.py   # AI модель
│   │   ├── db_service.py   # SQLite БД
│   │   └── notification_service.py
│   ├── widgets/            # UI компоненты
│   │   ├── message_bubble.py
│   │   └── status_bar.py  # Индикатор статуса AI
│   ├── models/             # Модели данных
│   ├── i18n/               # Переводы
│   └── utils/              # Утилиты
├── google_gemma-3-1b-it-Q5_K_M.gguf  # AI модель
├── requirements.txt
└── main.py
```

### Настройка

- **AI Модель**: Gemma 3B GGUF (Q5_K_M квантование)
- **База данных**: SQLite в папке данных приложения
- **Тема**: Системная/Светлая/Тёмная через настройки
- **Язык**: Автоопределение или ручной выбор
- **Лимит контекста**: 1024 токена (авто-резюме при переполнении)

### Лицензия

MIT License - см. файл LICENSE.

---

<div align="center">

**Made with Python + Flet**

</div>
