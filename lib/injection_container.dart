import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'core/constants/app_constants.dart';
import 'core/network/network_info.dart';
import 'data/datasources/local/inventory_local_datasource.dart';
import 'data/datasources/remote/sheets_remote_datasource.dart';
import 'data/datasources/remote/google_apps_script_datasource.dart' as gas;
import 'data/repositories/inventory_repository_impl.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/usecases/add_inventory_item.dart';
import 'domain/usecases/get_inventory_items.dart';
import 'domain/usecases/get_transactions.dart';
import 'domain/usecases/update_stock.dart';
import 'domain/usecases/delete_inventory_item.dart';
import 'presentation/blocs/inventory/inventory_bloc.dart';
import 'core/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
    () => InventoryBloc(
      getInventoryItems: sl(),
      addInventoryItem: sl(),
      updateStock: sl(),
      deleteInventoryItem: sl(),
      notificationService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetInventoryItems(sl()));
  sl.registerLazySingleton(() => AddInventoryItem(sl()));
  sl.registerLazySingleton(() => UpdateStock(sl()));
  sl.registerLazySingleton(() => DeleteInventoryItem(sl()));
  sl.registerLazySingleton(() => GetTransactions(sl()));

  // Repository
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  // Register HTTP client
  sl.registerLazySingleton(() => http.Client());

  // Use GoogleAppsScriptDataSource instead of SheetsRemoteDataSourceImpl
  sl.registerLazySingleton<SheetsRemoteDataSource>(
    () => gas.GoogleAppsScriptDataSource(client: sl()),
  );

  sl.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  // Google Sheets API setup
  // Comment out as we're using Google Apps Script now
  /*
  final credentials = ServiceAccountCredentials.fromJson({
    "type": "service_account",
    "project_id": "inventory-manager-454318",
    "private_key_id": "db6d5337be30ae1854b65fac3c6d929031f0a6bb",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDaaPP6iyXE+axL\nl5wY4Ui8ReYw41LuWd3P0IlMnv/YdT8EUvnosUvncgb0tMACSud3ZfG3KucMzNna\nNrfkw3EvsArCxqvdlSrBLI5eLTs7lH2YeSA8SEUgT+46qjt1jsZiF8lU1yGLW8MD\nz+XUHIIy5Zqau18W0sWdRE7DIsBR20GzHH1E26LY5j8rX//ViE03XUs7+KpZWo+U\nfDwTijdEu4g4FKD4iGmG7GbQ9L/q7Zv3N90cOYB6U9J+C0MyM6JkcAbRxWWvNPuW\njnWL5rEqwr7lLEFTS7fWZNJOKxZrSrGZByU3FOTsggM/DtovY0hqVzWFt4I/teHO\nLhEfqCGnAgMBAAECggEABcMZFLYRFAZGPmRMkPd4lMb/ULDeoj0qte3ZgXT8aPiG\n5hVOVI5A42VFu7T9D9JsEuFUpDF0kQjignhJF7b0SH7LeeIF7L2fuCL1ypRE6Mh9\nG8WuTQjXEggpz9Bn6y0OHM5l2GAomWWdWn9kn9j0smUOVCC3XIHJBuIjddB35HDo\n4hLMbNXiOoPM6t8JwEVEAFW1G8YawMWQsCtgt/3/drG2nKLhH6GZIAGZXyjel8R1\nqnQssa5okNT13LRFVsftKkBTo6vb0naF0oGovBFD1tJKGWYFMXpAFLuHzt1PDB8a\nk240/Uk+iB6mpQ/9MAJdXnJ0uKFjK+py5FL/nDb90QKBgQD/nohHoG4zigLikHsK\nXaKUbsO019r4Oc8cURMHqBI+HoAMmqgMH/s+55WaKx+uHSVIbGJ9h9F0R8+mnAAw\nPKh0N3PwCtE6P6CB/Kzhqxjf0U7DqmPp0FxWv+gdsEHM9iL225Cmcss2BjzL0aFA\n42JSCux2C2yqcXFz+lB5MGXTvwKBgQDavDuYKHQWj0p/TN89h3ECIjiKeY2zeV8c\nibsZkNKFHSyhnX/deA5QJAs7SUHunmUPckdcDCx9bfWh8DzREE2+EO2YVQUfsPj3\nmRHPcJKbSzhS7cW8tmUnfnwIgoCerYtrmHq6ERj/ZD6WrI6UaT0FDwuE1Qnfdcg7\nqwQ/XJaMGQKBgAGIaNbNHnwOos/LAAHi59uuAlxuQvDkH9rSnaOZHWrj8e6hasqP\n0ojhCKOhCJKZuCSECd8o1le1KoicPOANLRFtV7OjzPdldEfzRPIhfYeyEJ/ZwLmh\nNzyJ8BFlgi+Bdlo2nNpyq8dKKEksm6Pw+SD20c4vaVpoTb7dTGg9ow6vAoGBAIhY\n1X0fml2FrJZ1wKKGDveZhU0sQBwkCBmt8Scak1/Os8d6ef3/nExwa1/lZmfr7GsY\nfUrve7wkEv2C1yYq14sm2jQeqzb6BfexPtzj+z86QD3RYXUk7SEVQxO65ZoD6+iB\n/96EUeTBBBLANZBlmVfR7Qg8FA9rSAmJrPgiKuXhAoGBAO8EreoOuOzeLeHACqxa\nRU02/FODI95KTs1S5VIxeLzHr8ZiUdoSLMc0JRHfzCpIsEymY3yepJFKEZLlX6hJ\nZJYoxtASS13Y4wGepVZzXnyYfYAzxZpl53V9rQ612qR2rbQI72l1wPO/ydbh9Fxt\nkQ8DlTwuwegeY9tlrwaMjBYA\n-----END PRIVATE KEY-----\n",
    "client_email":
        "inventory-manager-service@inventory-manager-454318.iam.gserviceaccount.com",
    "client_id": "113217206152390784343",
  });

  final scopes = [SheetsApi.spreadsheetsScope];
  final client = await clientViaServiceAccount(credentials, scopes);
  final sheetsApi = SheetsApi(client);

  sl.registerLazySingleton(() => sheetsApi);
  */

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  sl.registerLazySingleton(() => flutterLocalNotificationsPlugin);

  sl.registerLazySingleton(
    () =>
        NotificationService(notificationsPlugin: sl(), sharedPreferences: sl()),
  );
}
