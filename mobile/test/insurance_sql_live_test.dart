import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/api_quotation_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

void main() {
  final credentials = Platform.environment['GARAGE_VERIFY_CREDENTIALS'];
  final share = Platform.environment['GARAGE_VERIFY_SHARE'];
  test(
    'Flutter reads the insurer decision and customer share shown on Web',
    () async {
      final config = jsonDecode(await File(credentials!).readAsString());
      expect(config['database'], startsWith('QuanLyGaraOTo_Verify_'));
      final expected = jsonDecode(await File(share!).readAsString());
      final auth = ApiAuthService();
      final user = config['customer'];
      final session = await auth.login(
        username: user['username'],
        password: user['password'],
      );
      try {
        final service = ApiQuotationService(
          CustomerApi(() => session.accessToken),
        );
        final result = await service.getCoverage(
          expected['quoteId'].toString(),
        );
        expect(result?['approved'], expected['approved']);
        expect(result?['customerAmount'], expected['customerAmount']);
        expect(result?['direct'], true);
        expect(result, isNot(contains('documents')));
      } finally {
        await auth.logout(session);
      }
    },
    skip: credentials == null || share == null
        ? 'Run the insurance Web scenario first.'
        : false,
  );
}
