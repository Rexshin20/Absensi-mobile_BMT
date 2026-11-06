import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Alamat API Laravel. Untuk uji di HP lewat kabel USB pakai `adb reverse tcp:8000 tcp:8000`
/// (lihat README). Untuk server asli: flutter build apk --dart-define=API_BASE_URL=https://domain-anda/api
const String apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

final ApiClient api = ApiClient();

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class Office {
  Office({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int radiusM;

  factory Office.fromJson(Map<String, dynamic> json) => Office(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusM: (json['radius_m'] as num).toInt(),
      );
}

class Employee {
  Employee({
    required this.name,
    this.position,
    this.division,
    this.office,
  });

  final String name;
  final String? position;
  final String? division;
  final Office? office;

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        name: json['name'] as String,
        position: json['position'] as String?,
        division: json['division'] as String?,
        office: json['office'] == null
            ? null
            : Office.fromJson(json['office'] as Map<String, dynamic>),
      );
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employee,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final Employee? employee;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        employee: json['employee'] == null
            ? null
            : Employee.fromJson(json['employee'] as Map<String, dynamic>),
      );
}

class TodayAttendance {
  TodayAttendance({
    required this.date,
    required this.checkInTime,
    required this.status,
    this.office,
    this.distanceM,
    this.source,
    this.photoUrl,
  });

  final String date;
  final String checkInTime;
  final String status;
  final String? office;
  final int? distanceM;
  final String? source;
  final String? photoUrl;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) =>
      TodayAttendance(
        date: json['date'] as String,
        checkInTime: json['check_in_time'] as String,
        status: json['status'] as String,
        office: json['office'] as String?,
        distanceM: json['distance_m'] == null
            ? null
            : (json['distance_m'] as num).toInt(),
        source: json['source'] as String?,
        photoUrl: json['photo_url'] as String?,
      );
}

class AttendanceRecord {
  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    required this.status,
    this.office,
    this.distanceM,
    this.source,
    this.photoUrl,
  });

  final String date;
  final String checkInTime;
  final String status;
  final String? office;
  final int? distanceM;
  final String? source;
  final String? photoUrl;

  bool get isLate => status == 'Terlambat';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: json['date'] as String,
        checkInTime: json['check_in_time'] as String,
        status: json['status'] as String,
        office: json['office'] as String?,
        distanceM: json['distance_m'] == null
            ? null
            : (json['distance_m'] as num).toInt(),
        source: json['source'] as String?,
        photoUrl: json['photo_url'] as String?,
      );
}

class MonthSummary {
  const MonthSummary({
    required this.workDays,
    required this.present,
    required this.late,
    required this.leave,
  });

  final int workDays;
  final int present;
  final int late;
  final int leave;

  int get total => present + late;

  factory MonthSummary.fromJson(Map<String, dynamic> json) => MonthSummary(
        workDays: (json['work_days'] as num).toInt(),
        present: (json['present'] as num).toInt(),
        late: (json['late'] as num).toInt(),
        leave: (json['leave'] as num).toInt(),
      );
}

class HistoryResult {
  HistoryResult({required this.month, required this.summary, required this.records});

  final String month;
  final MonthSummary summary;
  final List<AttendanceRecord> records;

  factory HistoryResult.fromJson(Map<String, dynamic> json) => HistoryResult(
        month: json['month'] as String,
        summary: MonthSummary.fromJson(json['summary'] as Map<String, dynamic>),
        records: (json['records'] as List<dynamic>)
            .map((record) => AttendanceRecord.fromJson(record as Map<String, dynamic>))
            .toList(),
      );
}

class LeaveTypeOption {
  LeaveTypeOption({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory LeaveTypeOption.fromJson(Map<String, dynamic> json) =>
      LeaveTypeOption(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}

class LeaveRecord {
  LeaveRecord({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    this.note,
    this.reason,
  });

  final int id;
  final String? type;
  final String startDate;
  final String endDate;
  final int days;
  final String status;
  final String? note;
  final String? reason;

  bool get isPending => status == 'Menunggu';
  bool get isApproved => status == 'Disetujui';

  factory LeaveRecord.fromJson(Map<String, dynamic> json) => LeaveRecord(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String?,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        days: (json['days'] as num?)?.toInt() ?? 0,
        status: json['status'] as String,
        note: json['note'] as String?,
        reason: json['reason'] as String?,
      );
}

class TodayInfo {
  TodayInfo({
    required this.user,
    required this.workStart,
    required this.workDays,
    this.today,
  });

  final AppUser user;
  final String workStart;
  final List<int> workDays;
  final TodayAttendance? today;

  factory TodayInfo.fromJson(Map<String, dynamic> json) => TodayInfo(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        workStart: json['work_start'] as String,
        workDays: (json['work_days'] as List<dynamic>)
            .map((day) => (day as num).toInt())
            .toList(),
        today: json['today'] == null
            ? null
            : TodayAttendance.fromJson(json['today'] as Map<String, dynamic>),
      );
}

class CheckInResult {
  CheckInResult({required this.message, required this.attendance});

  final String message;
  final TodayAttendance attendance;

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
        message: json['message'] as String,
        attendance: TodayAttendance.fromJson(
          json['attendance'] as Map<String, dynamic>,
        ),
      );
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final http.Client _client;
  String? _token;

  bool get hasSession => _token != null && _token!.isNotEmpty;

  Future<bool> restoreSession() async {
    _token = await _storage.read(key: _tokenKey);
    return hasSession;
  }

  Future<void> forgetSession() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<AppUser> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    final payload = data as Map<String, dynamic>;
    _token = payload['token'] as String;
    await _storage.write(key: _tokenKey, value: _token);
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<TodayInfo> fetchToday() async {
    final data = await _request('GET', '/me');
    return TodayInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckInResult> checkIn({
    required double latitude,
    required double longitude,
    required Uint8List photoBytes,
  }) async {
    final uri = Uri.parse('$apiBase/attendance');
    final request = http.MultipartRequest('POST', uri)
      ..fields['latitude'] = latitude.toStringAsFixed(7)
      ..fields['longitude'] = longitude.toStringAsFixed(7)
      ..headers.addAll({
        'Accept': 'application/json',
        if (hasSession) 'Authorization': 'Bearer $_token',
      })
      ..files.add(
        http.MultipartFile.fromBytes('photo', photoBytes, filename: 'selfie.jpg'),
      );

    http.Response response;
    try {
      response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 45)),
      );
    } on TimeoutException {
      throw ApiException('Server tidak menjawab saat mengirim absen. Coba lagi.');
    } catch (error, stackTrace) {
      debugPrint('API request failed ($uri): $error');
      debugPrintStack(stackTrace: stackTrace);
      throw ApiException(
        'Tidak bisa terhubung ke server. Pastikan API aktif dan alamat server dapat dijangkau HP.',
      );
    }

    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFrom(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return CheckInResult.fromJson(decoded as Map<String, dynamic>);
  }

  Future<HistoryResult> fetchHistory(String month) async {
    final data = await _request('GET', '/attendance?month=$month');
    return HistoryResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<LeaveRecord>> fetchLeaves() async {
    final data = await _request('GET', '/leaves');
    return (data['leaves'] as List<dynamic>)
        .map((leave) => LeaveRecord.fromJson(leave as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaveTypeOption>> fetchLeaveTypes() async {
    final data = await _request('GET', '/leave-types');
    return (data['leave_types'] as List<dynamic>)
        .map((type) => LeaveTypeOption.fromJson(type as Map<String, dynamic>))
        .toList();
  }

  Future<String> submitLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String note,
  }) async {
    final data = await _request(
      'POST',
      '/leaves',
      body: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'note': note,
      },
    );
    return (data as Map<String, dynamic>)['message'] as String;
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } on ApiException {
      // Token mungkin sudah kedaluwarsa; sesi lokal tetap dibersihkan.
    }
    await forgetSession();
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$apiBase$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (withAuth && hasSession) 'Authorization': 'Bearer $_token',
    };

    http.Response response;
    try {
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        _ => throw ArgumentError('Metode $method belum didukung.'),
      };
      response = await future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('Server tidak menjawab. Coba lagi sebentar lagi.');
    } catch (error, stackTrace) {
      debugPrint('API request failed ($uri): $error');
      debugPrintStack(stackTrace: stackTrace);
      throw ApiException(
        'Tidak bisa terhubung ke server. Pastikan API aktif dan alamat server dapat dijangkau HP.',
      );
    }

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _messageFrom(decoded, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  String _messageFrom(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
        }
      }
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Permintaan gagal ($statusCode).';
  }
}
