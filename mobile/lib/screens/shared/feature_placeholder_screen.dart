import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/feedback_states.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.embedded = false,
  });

  final String title;
  final IconData icon;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = EmptyState(
      icon: icon,
      title: 'Không thể mở trang này',
      message:
          'Đường dẫn không tồn tại hoặc không còn khả dụng. Vui lòng quay lại trang trước.',
    );
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: content),
      backgroundColor: AppColors.background,
    );
  }
}
