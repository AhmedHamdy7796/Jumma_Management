import 'package:flutter/material.dart';
import 'package:gomaa_management/features/customer/presentation/pages/customers_screen.dart';
import 'package:gomaa_management/features/purchase/presentation/pages/purchases_screen.dart';
import 'package:gomaa_management/features/fix/presentation/pages/fixes_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CustomersScreen(),
    const PurchasesScreen(),
    const FixesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'العملاء'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'المشتريات',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الصيانة'),
          ],
        ),
      ),
    );
  }
}
