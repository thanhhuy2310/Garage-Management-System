import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/remembered_session.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

void main() {

  final file = Platform.environment['GARAGE_VERIFY_CREDENTIALS'];
  test(
    'resume a stored SQL session and reject it after logout',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final fixture = jsonDecode(await File(file!).readAsString());
      expect(fixture['database'], startsWith('QuanLyGaraOTo_Verify_'));
      final user = fixture['customer'];
      final login = await ApiAuthService().login(
        username: user['username'],
        password: user['password'],
      );
      final storage = RememberedSession();
      expect(await storage.restore(), isNull);
      await storage.save(login.accessToken);
      expect(
        (await RememberedSession().restore())?.customerId,
        login.customerId,
      );
      await CustomerApi(() => login.accessToken)
          .request('/auth/logout', method: 'POST');
      expect(await RememberedSession().restore(), isNull);
    },
    skip: file == null
        ? 'Requires isolated SQL verification credentials'
        : false,
  );
}
