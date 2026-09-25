import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/constants/app_config.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final success = await widget.controller.signIn(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth > 520 ? 440 : double.infinity,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.car_repair_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Đăng nhập',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            AppConfig.garageName,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AppTextField(
                            controller: _usernameController,
                            label: 'Tên đăng nhập',
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            enabled: !widget.controller.signingIn,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập tên đăng nhập.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !widget.controller.signingIn,
                            onSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Vui lòng nhập mật khẩu.'
                                : null,
                          ),
                          if (widget.controller.authError != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.danger,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.controller.authError!,
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Đăng nhập',
                            onPressed: _submit,
                            loading: widget.controller.signingIn,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Android Emulator kết nối backend qua 10.0.2.2:8080.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
