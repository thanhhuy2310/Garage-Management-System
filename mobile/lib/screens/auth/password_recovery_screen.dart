import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, this.contactToken});
  final String? contactToken;
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryState();
}

class _PasswordRecoveryState extends State<PasswordRecoveryScreen> {
  final email = TextEditingController(),
      code = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  final client = HttpClient();
  int step = 0;
  bool busy = false;
  String ticket = '', error = '';

  @override
  void dispose() {
    for (final field in [email, code, password, confirmation]) {
      field.dispose();
    }
    client.close(force: true);
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    final address = email.text.trim();
    if (address.isEmpty ||
        (step == 1 && !RegExp(r'^[0-9]{6}$').hasMatch(code.text)) ||
        (step == 2 &&
            (password.text.length < 8 || password.text != confirmation.text))) {
      setState(
        () => error = [
          'Nhập email liên kết với tài khoản.',
          'Nhập mã gồm 6 chữ số.',
          'Mật khẩu cần ít nhất 8 ký tự và phải khớp.',
        ][step],
      );
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final changing = widget.contactToken != null;
      final purpose = changing ? 'contact-email' : 'recovery';
      final route = ['request', 'verify', 'complete'][step];
      final request = await client
          .postUrl(Uri.parse('${AppConfig.apiBaseUrl}/auth/$purpose/$route'))
          .timeout(const Duration(seconds: 12));
      if (changing) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${widget.contactToken}',
        );
      }
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'email': address,
          if (changing && step == 0) 'password': password.text,
          if (step == 1) 'code': code.text,
          if (step == 2) ...{
            'ticket': ticket,
            'password': password.text,
            'confirmation': confirmation.text,
          },
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final data = jsonDecode(
        await utf8.decoder
            .bind(response)
            .join()
            .timeout(const Duration(seconds: 12)),
      );
      if (!mounted) return;
      if (response.statusCode >= 400) {
        setState(() => error = data['message'] ?? 'Không thể xử lý yêu cầu.');
        return;
      }
      if (changing && step == 1) {
        Navigator.pop(context, address);
        return;
      }
      if (changing) password.clear();
      if (step == 1) ticket = data['data'] as String;
      if (step == 2) {
        ticket = '';
        password.clear();
        confirmation.clear();
      }
      setState(() => step++);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Không kết nối được gara. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.contactToken == null
            ? 'Quên mật khẩu'
            : 'Cập nhật email khôi phục',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (step == 0)
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email liên kết với tài khoản',
            ),
          ),
        if (step == 0 && widget.contactToken != null)
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
          ),
        if (step == 1) ...[
          Text(
            widget.contactToken != null
                ? 'Nhập mã trong hộp thư ${email.text.trim()}.'
                : 'Nếu email ${email.text.trim()} liên kết với tài khoản, hãy kiểm tra hộp thư và nhập mã trong 15 phút.',
          ),
          TextField(
            controller: code,
            maxLength: 6,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(labelText: 'Mã xác minh'),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    step = 0;
                    error = '';
                    code.clear();
                  }),
            child: const Text('Nhập lại email hoặc yêu cầu mã mới'),
          ),
        ],
        if (step == 2) ...[
          TextField(
            controller: password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
          ),
          TextField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nhập lại mật khẩu mới',
            ),
          ),
        ],
        if (error.isNotEmpty)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        if (step < 3)
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(
              busy
                  ? 'Đang xử lý…'
                  : ['Gửi mã xác minh', 'Xác minh', 'Đổi mật khẩu'][step],
            ),
          ),
        if (step == 3) ...[
          const Text(
            'Đã đổi mật khẩu. Bạn có thể đăng nhập bằng mật khẩu mới.',
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Về đăng nhập'),
          ),
        ],
      ],
    ),
  );
}
