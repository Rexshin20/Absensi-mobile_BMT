import 'package:flutter/foundation.dart';

import 'api.dart';

String get currentMonth {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

class AppStore extends ChangeNotifier {
  AppStore(this._api);

  final ApiClient _api;

  TodayInfo? info;
  HistoryResult? history;
  List<LeaveRecord> leaves = const [];
  List<LeaveTypeOption> leaveTypes = const [];
  String month = currentMonth;

  bool loading = false;
  bool submitting = false;
  String? error;

  AppUser? get user => info?.user;

  void markSubmitting(bool value) {
    submitting = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      info = await _api.fetchToday();
    } on ApiException catch (exception) {
      loading = false;
      error = exception.message;
      notifyListeners();
      rethrow;
    }

    final results = await Future.wait([
      _run(() async => history = await _api.fetchHistory(month)),
      _run(() async => leaves = await _api.fetchLeaves()),
      _run(() async => leaveTypes = await _api.fetchLeaveTypes()),
    ]);

    loading = false;
    error = results.whereType<String>().firstOrNull;
    notifyListeners();
  }

  Future<void> loadMonth(String value) async {
    month = value;
    notifyListeners();
    await _run(() async => history = await _api.fetchHistory(month));
    notifyListeners();
  }

  Future<String> checkIn({
    required double latitude,
    required double longitude,
    required Uint8List photoBytes,
  }) async {
    final result = await _api.checkIn(
      latitude: latitude,
      longitude: longitude,
      photoBytes: photoBytes,
    );
    await refresh();
    return result.message;
  }

  Future<String> submitLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String note,
  }) async {
    final message = await _api.submitLeave(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      note: note,
    );
    leaves = await _api.fetchLeaves();
    notifyListeners();
    return message;
  }

  Future<void> logout() => _api.logout();

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on ApiException catch (exception) {
      return exception.message;
    }
  }
}
