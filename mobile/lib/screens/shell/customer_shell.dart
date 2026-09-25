import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../home/home_screen.dart';
import '../shared/feature_placeholder_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.controller,
    this.initialIndex = 0,
  });

  final AppController controller;
  final int initialIndex;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _index = widget.initialIndex;

  void _selectTab(int index) => setState(() => _index = index);

  void _openRoute(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        controller: widget.controller,
        onSelectTab: _selectTab,
        onOpenRoute: _openRoute,
      ),
      const FeaturePlaceholderScreen(
        title: 'Đặt lịch',
        icon: Icons.calendar_month_outlined,
        embedded: true,
      ),
      const FeaturePlaceholderScreen(
        title: 'Theo dõi sửa chữa',
        icon: Icons.car_repair_outlined,
        embedded: true,
      ),
      const FeaturePlaceholderScreen(
        title: 'Thông báo',
        icon: Icons.notifications_none,
        embedded: true,
      ),
      const FeaturePlaceholderScreen(
        title: 'Tài khoản',
        icon: Icons.person_outline,
        embedded: true,
      ),
    ];
    const titles = [
      'Trang chủ',
      'Đặt lịch',
      'Theo dõi',
      'Thông báo',
      'Tài khoản',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: _index == 0
            ? [
                IconButton(
                  tooltip: 'Xem thông báo',
                  onPressed: () => _selectTab(3),
                  icon: const Badge(
                    smallSize: 7,
                    child: Icon(Icons.notifications_none),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Đặt lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.car_repair_outlined),
            selectedIcon: Icon(Icons.car_repair),
            label: 'Theo dõi',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
