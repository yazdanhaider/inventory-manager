# Inventory Manager Stockorad

![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0.0+-blue.svg)
![BLoC](https://img.shields.io/badge/BLoC-9.0.0-purple.svg)


A modern inventory management system built with Flutter that uses Google Sheets as a backend. This app allows businesses to efficiently track stock levels, manage inventory, and receive low-stock alerts.

## Features

### Home Screen

- Displays a list of inventory items with name, quantity, last updated date, and stock status
- Visual indicators for low stock items
- Search and filter functionality
- Pull-to-refresh for real-time updates

### Inventory Management

- Add new inventory items with name, initial quantity, price, and threshold values
- Edit existing inventory items
- Mark items as inactive (soft delete)
- Simple and intuitive user interface

![Cyan Gradient Technology Startup Business Company Presentation](https://github.com/user-attachments/assets/31a5b035-1fa6-4dc7-b6a2-23f78ca651e8)

### Stock Operations

- Record stock-in and stock-out transactions
- Automatic stock level updates
- Transaction logging with date, time, and details
- Recent transactions view on the stock operations page

### Transaction History

- Complete log of all inventory changes
- Date-wise grouping for better organization
- Visual differentiation between stock-in and stock-out operations
- Detailed timestamp and quantity information
  
![3](https://github.com/user-attachments/assets/a5c61ba2-9d06-4f93-b4b8-6d346a1b02d8)

### Low Stock Alerts

- Automatic notifications when stock falls below threshold
- Configurable threshold levels per item
- Visual indicators on the inventory list
- Notification history tracking
  
![2](https://github.com/user-attachments/assets/216fc735-1495-471d-8dab-ab2d91c17198)


## Architecture

This application follows Clean Architecture principles with a clear separation of layers:

### Domain Layer

- Entities: Core business objects like `InventoryItem` and `Transaction`
- Repositories: Abstract interfaces for data operations
- Use Cases: Business logic operations

### Data Layer

- Data Sources: Remote (Google Sheets) and Local (SharedPreferences)
- Models: Data objects with serialization/deserialization
- Repository Implementations

### Presentation Layer

- Pages/Screens: User Interface
- Widgets: Reusable UI components
- BLoCs: State management for UI

## Technologies Used

### Core Framework

- Flutter & Dart

### State Management

- BLoC Pattern (bloc, flutter_bloc packages)
- Repository Pattern

### Backend Integration

- Google Sheets API via Google Apps Script
- HTTP for API communication

### Local Storage

- SharedPreferences for caching and user settings
- SQLite (sqflite) for offline capabilities

### UI Components

- Material Design 3
- Flutter Slidable for swipe actions
- Shimmer for loading effects

### Utilities

- Equatable for equality comparisons
- Dartz for functional programming and error handling
- GetIt for dependency injection
- Intl for date formatting and localization

### Notifications

- Flutter Local Notifications
- Timezone for time-based notifications

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK (3.0.0 or higher)
- A Google account for Google Sheets API

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yazdanhaider/inventory-manager
cd inventory-manager
```

2. Install dependencies:

```bash
flutter pub get
```

3. Set up Google Sheets (see [Google Sheets Integration](https://developers.google.com/workspace/sheets/api/reference/rest))

4. Run the app:

```bash
flutter run
```

## Google Sheets Integration

This app uses Google Sheets as a backend database through Google Apps Script. The setup involves:

1. Create a new Google Sheet with three tabs:

   - **Inventory**: For storing inventory items data
   - **InventoryTransactions**: For logging stock changes
   - **Notifications**: For tracking low stock alerts

2. Set up Google Apps Script:
   - Open the Google Sheet and go to Extensions > Apps Script
   - Create a new script and set up API endpoints for CRUD operations
   - Deploy the script as a web app
   - Update the `appsScriptUrl` in `app_constants.dart` with your deployment URL

For more detailed instructions on setting up the Google Apps Script, refer to the [Google Apps Script Setup Guide](https://developers.google.com/apps-script).

## Key Components

### Inventory Management

The core functionality is centered around `InventoryBloc` which handles:

- Fetching and displaying inventory items
- Adding new items
- Updating stock quantities
- Filtering and sorting
- Search functionality

### Stock Operations

The `StockOperationPage` allows users to:

- Select items for stock changes
- Record stock-in (additions) or stock-out (removals)
- View recent transactions
- Navigate to full transaction history

### Transaction Tracking

The app maintains a detailed log of all inventory changes:

- Each transaction includes item name, quantity, type, and timestamp
- Transactions are grouped by date for easy reference
- Complete history view with filtering options

### Notification System

The `NotificationService` provides:

- Automatic checking of stock levels
- Local notifications for low stock items
- Configurable threshold values per item
- Test notification functionality


## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Google Sheets API](https://developers.google.com/sheets/api)
- [BLoC Pattern](https://bloclibrary.dev/)
- All the package authors for their amazing work
