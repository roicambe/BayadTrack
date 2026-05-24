import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'data_screen.dart';
import 'printer_screen.dart';
import 'settings_screen.dart';

/// MainShell is the root screen after the app launches.
/// It holds the bottom navigation bar and switches between the 4 main tabs.
///
/// [IndexedStack] is used instead of Navigator so each tab preserves its
/// scroll position and state when you switch between tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // The four main screens — order matches the navigation bar destinations below
  static const List<Widget> _screens = [
    HomeScreen(),
    DataScreen(),
    PrinterScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // allows body to scroll behind the floating nav bar
      
      // PageView allows swipe gestures to switch between tabs
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, bottom: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NavigationBar(
                height: 65,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                // Only show labels for the active tab to keep it clean
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                animationDuration: const Duration(milliseconds: 250),
                destinations: const [
                  NavigationDestination(
                    icon:         Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Data',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.print_outlined),
                    selectedIcon: Icon(Icons.print_rounded),
                    label: 'Printer',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
