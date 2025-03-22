class AppConstants {
  static const String appName = 'Inventory Manager';
  static const String sheetId = '1BQDqW7ADWcl8Onmoihqu__f_qQ2lB4nPwAP8hkp06Wg';
  static const String inventoryRange = 'Inventory!A1:G';
  static const String transactionsRange = 'InventoryTransactions!A1:G';
  static const String notificationsRange = 'Notifications!A1:E';
  static const int lowStockThreshold = 5;

  // Sheet tab names
  static const String inventoryTab = 'Inventory';
  static const String transactionsTab = 'Transactions';
  static const String notificationsTab = 'Notifications';

  // Google Apps Script URL
  static const String appsScriptUrl =
      'https://script.google.com/macros/s/AKfycbwI5Qa-Ln69_7YTvg6YzQEdqYW99X0ctCtWhq4glCdSPoahRnvoo892bWh4vkFw9l7h/exec';
}
