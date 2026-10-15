import 'package:flutter/material.dart';
class DemoNotice extends StatelessWidget implements PreferredSizeWidget {
  const DemoNotice({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, color: const Color(0xFFFFF3CD), padding: const EdgeInsets.all(10), child: const Text('MOCK_ONLY · Dữ liệu minh họa. Thao tác không gửi lịch hẹn, báo giá hay thông báo đến gara.', style: TextStyle(fontSize: 12, color: Color(0xFF664D03))));
}
