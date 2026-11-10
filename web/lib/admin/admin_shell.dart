import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_admin/admin/dashboard_screen.dart';
import 'package:longvita_admin/admin/admin_instrumentation.dart';
import 'package:longvita_admin/admin/recipe_management_screen.dart';
import 'package:longvita_admin/admin/review_queue_screen.dart';

class AdminShell extends StatefulWidget {
  final User user;
  final String role;
  final Future<void> Function() onSignOut;
  const AdminShell({
    super.key,
    required this.user,
    required this.role,
    required this.onSignOut,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;

  static const destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Tổng quan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: Text('Công thức'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check),
      label: Text('Xét duyệt'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final instrumentation = context.watch<AdminWebInstrumentation>();
    final pages = [
      const DashboardScreen(),
      const RecipeManagementScreen(),
      ReviewQueueScreen(
        showGuidance: instrumentation.showReviewGuidance,
        refreshingConfig: instrumentation.refreshing,
        refreshConfig: instrumentation.refresh,
      ),
    ];
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.bgSurface),
            child: NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1120,
              selectedIndex: selected,
              onDestinationSelected: (value) =>
                  setState(() => selected = value),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: AppColors.actionPrimary),
                    SizedBox(width: 10),
                    Text('Longvita'),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      tooltip: 'Đăng xuất ${widget.user.email ?? ''}',
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ),
              ),
              destinations: destinations,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: selected, children: pages),
          ),
        ],
      ),
    );
  }
}
