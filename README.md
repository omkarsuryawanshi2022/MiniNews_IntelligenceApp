# Mini News Intelligence App

A Flutter-based news application that allows users to browse news by category, search articles, view article details, and save favorites for offline access.

## Features

- **Authentication:** Demo login, input validation, persistent session, and logout.
- **News Feed:** Category-based headlines, pagination, and pull-to-refresh.
- **Search:** API-based search with debouncing and pagination.
- **Article Details:** Article information, publisher details, and source links.
- **Favorites:** Save and remove articles with offline persistence using Hive.
- **Error Handling:** Loading indicators, empty states, API errors, and retry options.

## Tech Stack

- Flutter 3+ and Dart (Null Safety)
- Riverpod — State Management
- Dio — REST API Integration
- GoRouter — Navigation
- Hive — Local Storage
- NewsAPI — News Data

## Architecture

The application follows feature-first Clean Architecture, separating presentation, domain, and data layers.

```text
lib/
├── core/          # Configuration, networking, errors
├── features/
│   ├── auth/      # Authentication
│   ├── news/      # News feed, search, article details
│   └── favorites/ # Offline favorites
├── presentation/  # Navigation and shared widgets
├── app.dart
└── main.dart
test/              # Automated tests
tool/              # Development scripts
```

## API Configuration

1. Obtain an API key from [NewsAPI](https://newsapi.org/).
2. Create your local environment file:

   ```powershell
   Copy-Item .env.example .env
   ```

3. Add your API key to `.env` using the variable name expected by `tool/run.ps1`.
4. Connect your device and run:

   ```powershell
   flutter devices
   .\tool\run.ps1 -Device YOUR_DEVICE_ID
   ```

Flutter does not automatically load `.env`. The provided script is intended to pass the configuration using `--dart-define`.

**Security:** Never commit `.env` or expose your API key. Use a trusted backend to protect credentials in production.

## Installation and Testing

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build the Android debug APK:

```bash
flutter build apk --debug
```

## Authentication and Limitations

Authentication is a local demo login and does not validate credentials against a server. News availability depends on the API key, subscription, and usage limits. Full article text may require opening the original publisher's website.

## Testing Checklist

- [ ] Login and session persistence
- [ ] Category selection and pull-to-refresh
- [ ] Pagination without duplicate articles
- [ ] Search and empty results
- [ ] Article details and source links
- [ ] Favorites persistence after restart
- [ ] Offline access and error handling

## Developer

Developed as a Flutter Junior Developer assignment to demonstrate Clean Architecture, Riverpod state management, API integration, local persistence, and maintainable code.