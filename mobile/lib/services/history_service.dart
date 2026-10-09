// TV3-TUAN9
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_config.dart';
import '../models/history.dart';

class HistoryException implements Exception {
  const HistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tra cứu lịch sử sửa chữa, bảo dưỡng của khách hàng đang đăng nhập.
/// Backend lấy khách hàng từ JWT nên client không (và không thể) chọn customerId.
abstract interface class HistoryService {
  Future<List<HistoryItem>> getHistory({int? vehicleId});

  Future<HistoryDetail> getHistoryDetail(int repairOrderId);
}

class ApiHistoryService implements HistoryService {
  ApiHistoryService({
    required this.tokenProvider,
    String? baseUrl,
    HttpClient? client,
  }) : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _client = client ?? HttpClient();

  /// Trả về access token của phiên đăng nhập hiện tại (null khi chưa đăng nhập).
  final String? Function() tokenProvider;
  final String _baseUrl;
  final HttpClient _client;

  @override
  Future<List<HistoryItem>> getHistory({int? vehicleId}) async {
    final data = await _get(
      '/customers/me/history',
      query: vehicleId == null ? null : {'vehicleId': '$vehicleId'},
    );
    if (data is! List) {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(HistoryItem.fromJson)
        .toList();
  }

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    final data = await _get('/customers/me/history/$repairOrderId');
    if (data is! Map<String, dynamic>) {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
    try {
      return HistoryDetail.fromJson(data);
    } on FormatException {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
  }

  Future<Object?> _get(String path, {Map<String, String>? query}) async {
    final token = tokenProvider();
    if (token == null || token.isEmpty) {
      throw const HistoryException(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    try {
      var uri = Uri.parse('$_baseUrl$path');
      if (query != null) uri = uri.replace(queryParameters: query);
      final request = await _client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await utf8.decoder.bind(response).join();
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HistoryException(_errorMessage(response.statusCode, payload));
      }
      return payload['data'];
    } on HistoryException {
      rethrow;
    } on TimeoutException {
      throw const HistoryException(
        'Kết nối bị gián đoạn. Vui lòng kiểm tra mạng và thử lại.',
      );
    } on SocketException {
      throw const HistoryException(
        'Không thể kết nối đến hệ thống. Vui lòng kiểm tra mạng và thử lại.',
      );
    } on HttpException {
      throw const HistoryException(
        'Không thể kết nối đến hệ thống. Vui lòng thử lại.',
      );
    } on FormatException {
      throw const HistoryException(
        'Không thể xử lý dữ liệu lịch sử. Vui lòng thử lại.',
      );
    }
  }

  String _errorMessage(int statusCode, Map<String, dynamic> payload) {
    final message = payload['message']?.toString();
    return switch (statusCode) {
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền xem lịch sử này.',
      404 => message ?? 'Không tìm thấy dữ liệu lịch sử.',
      _ => message ?? 'Không thể tải lịch sử. Vui lòng thử lại.',
    };
  }
}
