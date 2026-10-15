import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/constants/app_config.dart';

class CustomerApi {
  CustomerApi(this.tokenProvider, {HttpClient? client, String? baseUrl}) : _client = client ?? HttpClient(), _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;
  final String? Function() tokenProvider;
  final HttpClient _client;
  final String _baseUrl;
  Future<dynamic> request(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final token = tokenProvider();
    if (token == null || token.isEmpty) throw StateError('Vui lòng đăng nhập lại.');
    try {
      final req = await _client.openUrl(method, Uri.parse('$_baseUrl$path')).timeout(const Duration(seconds: 12));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.headers.contentType = ContentType.json;
      if (body != null) req.write(jsonEncode(body));
      final response = await req.close().timeout(const Duration(seconds: 12));
      final text = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 12));
      final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode == 401) throw StateError('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      if (response.statusCode < 200 || response.statusCode >= 300 || payload['success'] == false) {
        throw StateError(payload['message']?.toString() ?? 'Không thể thực hiện yêu cầu.');
      }
      return payload['data'];
    } on SocketException { throw StateError('Không kết nối được gara. Vui lòng thử lại.'); }
      on TimeoutException { throw StateError('Kết nối quá thời gian. Vui lòng thử lại.'); }
  }
}
