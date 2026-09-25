import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/customer_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });
  final AppController controller;
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.controller.profile?.fullName,
  );
  late final _phone = TextEditingController(
    text: widget.controller.profile?.phone,
  );
  late final _email = TextEditingController(
    text: widget.controller.profile?.email,
  );
  late final _address = TextEditingController(
    text: widget.controller.profile?.address,
  );
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = widget.controller.profile;
    if (current == null) return;
    setState(() => _saving = true);
    await widget.controller.saveProfile(
      CustomerProfile(
        id: current.id,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin.')));
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để sử dụng ứng dụng.',
      confirmLabel: 'Đăng xuất',
      destructive: true,
    );
    if (!confirmed) return;
    await widget.controller.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primary,
            child: Text(
              _initials(profile?.fullName ?? 'Khách hàng'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          profile?.fullName ?? 'Khách hàng',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '@${widget.controller.session?.username ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _editing = !_editing),
                        icon: Icon(
                          _editing ? Icons.close : Icons.edit_outlined,
                          size: 18,
                        ),
                        label: Text(_editing ? 'Hủy' : 'Chỉnh sửa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _name,
                    label: 'Họ và tên',
                    enabled: _editing,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập họ tên.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phone,
                    label: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                    enabled: _editing,
                    validator: (value) =>
                        value == null || value.trim().length < 9
                        ? 'Số điện thoại không hợp lệ.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: _editing,
                    validator: (value) =>
                        value != null &&
                            value.isNotEmpty &&
                            !value.contains('@')
                        ? 'Email không hợp lệ.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _address,
                    label: 'Địa chỉ',
                    enabled: _editing,
                    maxLines: 2,
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Lưu thay đổi',
                      onPressed: _save,
                      loading: _saving,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                minTileHeight: 56,
                leading: const Icon(
                  Icons.password_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Đổi mật khẩu'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.changePassword),
              ),
              const Divider(height: 1),
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SafeArea(top: false, child: content),
    );
  }
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  return words
      .take(2)
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
      .join();
}
