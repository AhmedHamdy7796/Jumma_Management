import 'package:flutter/material.dart';
import 'package:gomaa_management/features/customer/presentation/pages/customers_screen.dart';
import 'package:gomaa_management/features/fix/presentation/pages/fixes_screen.dart';
import 'package:gomaa_management/features/purchase/presentation/pages/purchases_screen.dart';

import 'package:gomaa_management/features/profile/presentation/pages/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CustomersScreen(),
    const PurchasesScreen(),
    const FixesScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.people, label: 'العملاء'),
    _NavItem(icon: Icons.shopping_cart, label: 'المشتريات'),
    _NavItem(icon: Icons.build, label: 'الصيانة'),
    _NavItem(icon: Icons.person, label: 'الحساب'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(
                    color: Theme.of(context).primaryColor,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontFamily: 'Arial',
                  ),
                  destinations: _navItems.map((item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  )).toList(),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 14,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              items: _navItems.map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}
