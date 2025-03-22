import 'package:googleapis/sheets/v4.dart';

class MockSheetsApi implements SheetsApi {
  @override
  SpreadsheetsResource get spreadsheets => MockSpreadsheetsResource();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSpreadsheetsResource implements SpreadsheetsResource {
  @override
  SpreadsheetsValuesResource get values => MockSpreadsheetsValuesResource();

  @override
  Future<BatchUpdateSpreadsheetResponse> batchUpdate(
    BatchUpdateSpreadsheetRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchUpdateSpreadsheetResponse();
  }

  @override
  Future<Spreadsheet> create(Spreadsheet request, {String? $fields}) async {
    return Spreadsheet();
  }

  @override
  Future<Spreadsheet> get(
    String spreadsheetId, {
    String? $fields,
    bool? includeGridData,
    List<String>? ranges,
  }) async {
    return Spreadsheet();
  }

  @override
  Future<Spreadsheet> getByDataFilter(
    GetSpreadsheetByDataFilterRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return Spreadsheet();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSpreadsheetsValuesResource implements SpreadsheetsValuesResource {
  @override
  Future<ValueRange> get(
    String spreadsheetId,
    String range, {
    String? $fields,
    String? dateTimeRenderOption,
    String? majorDimension,
    String? valueRenderOption,
  }) async {
    // Return mock data
    return ValueRange(
      values: [
        ['ID', 'Name', 'Quantity', 'Price', 'Threshold', 'LastUpdated'],
        [
          '1',
          'Test Item 1',
          '10',
          '5.99',
          '5',
          DateTime.now().toIso8601String(),
        ],
        [
          '2',
          'Test Item 2',
          '20',
          '9.99',
          '8',
          DateTime.now().toIso8601String(),
        ],
      ],
    );
  }

  @override
  Future<AppendValuesResponse> append(
    ValueRange request,
    String spreadsheetId,
    String range, {
    String? $fields,
    bool? includeValuesInResponse,
    String? insertDataOption,
    String? responseDateTimeRenderOption,
    String? responseValueRenderOption,
    String? valueInputOption,
  }) async {
    // Mock successful append
    return AppendValuesResponse();
  }

  @override
  Future<UpdateValuesResponse> update(
    ValueRange request,
    String spreadsheetId,
    String range, {
    String? $fields,
    bool? includeValuesInResponse,
    String? responseDateTimeRenderOption,
    String? responseValueRenderOption,
    String? valueInputOption,
  }) async {
    // Mock successful update
    return UpdateValuesResponse();
  }

  @override
  Future<BatchClearValuesResponse> batchClear(
    BatchClearValuesRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchClearValuesResponse();
  }

  @override
  Future<BatchClearValuesByDataFilterResponse> batchClearByDataFilter(
    BatchClearValuesByDataFilterRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchClearValuesByDataFilterResponse();
  }

  @override
  Future<BatchGetValuesResponse> batchGet(
    String spreadsheetId, {
    String? $fields,
    String? dateTimeRenderOption,
    String? majorDimension,
    List<String>? ranges,
    String? valueRenderOption,
  }) async {
    return BatchGetValuesResponse();
  }

  @override
  Future<BatchGetValuesByDataFilterResponse> batchGetByDataFilter(
    BatchGetValuesByDataFilterRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchGetValuesByDataFilterResponse();
  }

  @override
  Future<BatchUpdateValuesResponse> batchUpdate(
    BatchUpdateValuesRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchUpdateValuesResponse();
  }

  @override
  Future<BatchUpdateValuesByDataFilterResponse> batchUpdateByDataFilter(
    BatchUpdateValuesByDataFilterRequest request,
    String spreadsheetId, {
    String? $fields,
  }) async {
    return BatchUpdateValuesByDataFilterResponse();
  }

  @override
  Future<ClearValuesResponse> clear(
    ClearValuesRequest request,
    String spreadsheetId,
    String range, {
    String? $fields,
  }) async {
    return ClearValuesResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
