import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.controller.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                controller: _current,
                label: 'Mật khẩu hiện tại',
                obscureText: _obscureCurrent,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập mật khẩu hiện tại.'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _next,
                label: 'Mật khẩu mới',
                obscureText: _obscureNext,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNext = !_obscureNext),
                  icon: Icon(
                    _obscureNext
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Mật khẩu phải có ít nhất 6 ký tự.'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirm,
                label: 'Nhập lại mật khẩu mới',
                obscureText: true,
                validator: (value) =>
                    value != _next.text ? 'Mật khẩu nhập lại chưa khớp.' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Đổi mật khẩu',
                onPressed: _submit,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
