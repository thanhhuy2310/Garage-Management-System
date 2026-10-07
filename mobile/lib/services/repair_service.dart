import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_config.dart';
import '../models/repair_order.dart';
import '../models/user_session.dart';

class RepairApiException implements Exception {
  const RepairApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class RepairService {
  Future<List<RepairOrder>> getRepairs(UserSession session);
}

class ApiRepairService implements RepairService {
  ApiRepairService({this.baseUrl = AppConfig.apiBaseUrl});
  final String baseUrl;

  @override
  Future<List<RepairOrder>> getRepairs(UserSession session) async {
    final client = HttpClient();
    try {
      return await _fetch(client, session).timeout(const Duration(seconds: 15));
    } on RepairApiException {
      rethrow;
    } on TimeoutException {
      throw const RepairApiException('Kết nối quá lâu. Vui lòng thử lại.');
    } on SocketException {
      throw const RepairApiException(
        'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.',
      );
    } on FormatException {
      throw const RepairApiException(
        'Dữ liệu tiến độ không hợp lệ. Vui lòng thử lại.',
      );
    } on HttpException {
      throw const RepairApiException('Kết nối bị gián đoạn. Vui lòng thử lại.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<RepairOrder>> _fetch(
    HttpClient client,
    UserSession session,
  ) async {
    final request = await client.getUrl(Uri.parse('$baseUrl/customer/repairs'));
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${session.accessToken}',
    );
    final response = await request.close();
    if (response.statusCode == 401) {
      throw const RepairApiException(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    final payload = jsonDecode(
      await utf8.decoder.bind(response).join(),
    ) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw RepairApiException(
        payload['message']?.toString() ?? 'Không tải được tiến độ sửa chữa.',
      );
    }
    final data = payload['data'];
    if (data is! List) throw const FormatException('Expected repair list');
    return data
        .map((item) => RepairOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
