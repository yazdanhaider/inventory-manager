import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inventory_item.dart';
import '../../data/datasources/remote/sheets_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../injection_container.dart' as di;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final SharedPreferences sharedPreferences;
  bool _isInitialized = false;

  NotificationService({
    required this.notificationsPlugin,
    required this.sharedPreferences,
  });

  Future<bool> initialize() async {
    if (_isInitialized) {
      print('Notification service already initialized');
      return true;
    }

    try {
      print('Starting notification service initialization');
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Initialize settings for both platforms
      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      // Initialize the plugin
      final bool? result = await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
        },
      );

      // Request permissions on Android 13+
      if (result != null && result) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
          print('Android notification permissions requested');
        }
      }

      _isInitialized = true;
      print('Notification service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing notification service: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> checkLowStockItems(List<InventoryItem> items) async {
    if (!_isInitialized) {
      print('Notification service not initialized, skipping low stock check');
      return;
    }

    try {
      print('Checking for low stock items...');
      for (var item in items) {
        if (item.quantity < item.threshold &&
            !item.name.startsWith('INACTIVE_')) {
          print(
            'Low stock detected for ${item.name}: ${item.quantity}/${item.threshold}',
          );

          // Check if we've already notified for this item in the last 3 days
          final lastNotified =
              sharedPreferences.getInt('notification_${item.id}') ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;

          // 3 days in milliseconds = 3 * 24 * 60 * 60 * 1000
          if (now - lastNotified > 3 * 24 * 60 * 60 * 1000) {
            print('Showing notification for ${item.name}');
            await _showLowStockNotification(item);

            // Save notification time
            await sharedPreferences.setInt('notification_${item.id}', now);

            // Log notification to Google Sheets
            try {
              final notification = NotificationModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                itemId: item.id,
                itemName: item.name,
                quantity: item.quantity,
                timestamp: DateTime.now(),
              );

              await di.sl<SheetsRemoteDataSource>().addNotification(
                notification,
              );
              print('Notification logged to Google Sheets');
            } catch (e) {
              print('Failed to log notification: $e');
            }
          } else {
            print('Notification for ${item.name} was already shown recently');
          }
        }
      }
    } catch (e) {
      print('Error checking low stock items: $e');
    }
  }

  Future<bool> _showLowStockNotification(InventoryItem item) async {
    if (!_isInitialized) {
      print('Notification service not initialized, cannot show notification');
      return false;
    }

    try {
      // Create Android notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'low_stock_channel',
            'Low Stock Notifications',
            channelDescription: 'Notifications for low stock items',
            importance: Importance.high,
            priority: Priority.high,
          );

      // Create iOS notification details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      // Combine platform-specific details
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Show the notification
      await notificationsPlugin.show(
        item.id.hashCode,
        'Low Stock Alert',
        '${item.name} is running low (${item.quantity} left)',
        platformChannelSpecifics,
      );

      print('Notification shown for ${item.name}');
      return true;
    } catch (e) {
      print('Error showing notification: $e');
      return false;
    }
  }

  // Test method to show a notification immediately
  Future<bool> showTestNotification() async {
    if (!_isInitialized) {
      print(
        'Notification service not initialized, cannot show test notification',
      );
      return false;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications channel',
            importance: Importance.high,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await notificationsPlugin.show(
        0,
        'Test Notification',
        'This is a test notification',
        platformChannelSpecifics,
      );

      print('Test notification shown');
      return true;
    } catch (e) {
      print('Error showing test notification: $e');
      return false;
    }
  }
}
