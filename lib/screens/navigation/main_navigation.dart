import 'package:flutter/material.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/screens/customers/customers_screen.dart';
import 'package:gomaa_management/screens/purchases/purchases_screen.dart';
import 'package:gomaa_management/screens/fixes/fixes_screen.dart';
import 'package:gomaa_management/screens/equipment/equipment_screen.dart';
import 'package:gomaa_management/screens/maintenance/maintenance_screen.dart';
import 'package:gomaa_management/screens/search/global_search_screen.dart';
import 'package:gomaa_management/screens/settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;

  final List<Widget> _screens = [
    const CustomersScreen(),
    const PurchasesScreen(),
    const FixesScreen(),
    const EquipmentScreen(),
    const MaintenanceScreen(),
    const GlobalSearchScreen(),
    const SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.people_outline, 'activeIcon': Icons.people, 'title': 'العملاء'},
    {'icon': Icons.shopping_cart_outlined, 'activeIcon': Icons.shopping_cart, 'title': 'المشتريات'},
    {'icon': Icons.build_outlined, 'activeIcon': Icons.build, 'title': 'صيانة عملاء'},
    {'icon': Icons.precision_manufacturing_outlined, 'activeIcon': Icons.precision_manufacturing, 'title': 'الأجهزة'},
    {'icon': Icons.handyman_outlined, 'activeIcon': Icons.handyman, 'title': 'الصيانة الدورية'},
    {'icon': Icons.search_outlined, 'activeIcon': Icons.search, 'title': 'بحث شامل'},
    {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'title': 'الإعدادات'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.cardDark : AppColors.white;

    return Scaffold(
      body: Row(
        children: [
          // Collapsible Premium Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isCollapsed ? 80 : 260,
            decoration: BoxDecoration(
              color: sidebarBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Branding Header
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16, left: 12, right: 12),
                  child: Row(
                    mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.end,
                    children: [
                      if (!_isCollapsed) ...[
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'جمعة لإدارة الأعمال',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'لوحة التحكم الإدارية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.darkGrey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.primaryGradient : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.end,
                              children: [
                                if (!_isCollapsed) ...[
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.white
                                          : (isDark ? AppColors.lightGrey : AppColors.secondary),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                                Icon(
                                  isSelected ? item['activeIcon'] : item['icon'],
                                  color: isSelected
                                      ? AppColors.white
                                      : (isDark ? AppColors.lightGrey : AppColors.primary),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Collapse Toggle Button
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  child: Align(
                    alignment: _isCollapsed ? Alignment.center : Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Container(
              color: isDark ? AppColors.black : AppColors.lightGrey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _screens[_selectedIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
