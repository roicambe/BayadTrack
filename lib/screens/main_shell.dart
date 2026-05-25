import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'home_screen.dart';
import 'data_screen.dart';
import 'printer_screen.dart';
import 'settings_screen.dart';
import '../services/app_dialog.dart';

/// MainShell is the root screen after the app launches.
/// It holds the bottom navigation bar and switches between the 4 main tabs.
///
/// [IndexedStack] is used instead of Navigator so each tab preserves its
/// scroll position and state when you switch between tabs.
///
/// It also listens for incoming share intents (images/text from GCash) and
/// automatically routes them to the DataScreen for OCR processing.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // GlobalKey so we can call DataScreenState methods from here
  final _dataScreenKey = GlobalKey<DataScreenState>();

  // Share intent subscription handle (cancelled in dispose)
  StreamSubscription<List<SharedFile>>? _sharingSubscription;

  // The four main screens — order matches the navigation bar destinations below
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    _screens = [
      const HomeScreen(),
      DataScreen(key: _dataScreenKey),
      const PrinterScreen(),
      const SettingsScreen(),
    ];

    _initSharingIntent();
  }

  // ── Share Intent Listener ─────────────────────────────────────────────────

  void _initSharingIntent() {
    final sharingPlugin = FlutterSharingIntent.instance;

    // Handle the intent that launched the app (cold start share)
    sharingPlugin.getInitialSharing().then(_handleSharedFiles);

    // Handle intents while the app is already running (warm share)
    _sharingSubscription = sharingPlugin
        .getMediaStream()
        .listen(_handleSharedFiles, onError: (_) {});
  }

  Future<void> _handleSharedFiles(List<SharedFile> files) async {
    if (files.isEmpty) return;

    // Switch to the Data tab immediately
    _switchToTab(1);

    // Wait one frame so DataScreen is mounted before we call into it
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    for (final file in files) {
      if (file.value == null) continue;

      if (file.type == SharedMediaType.TEXT ||
          file.type == SharedMediaType.URL) {
        // Plain text or URL — run through regex parser
        await _dataScreenKey.currentState?.processSharedText(file.value!);
      } else if (file.type == SharedMediaType.IMAGE) {
        // Image — run through OCR then regex parser
        await _dataScreenKey.currentState?.processSharedImagePath(file.value!);
      }
    }
  }

  // ── Tab Switching ─────────────────────────────────────────────────────────

  void _switchToTab(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sharingSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // Never let the system auto-pop; we intercept and show a dialog instead.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // already handled
        final shouldExit = await AppDialog.showExitConfirmation(context);
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
      extendBody: true, // allows body to scroll behind the floating nav bar

      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
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
                      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                      animationDuration: const Duration(milliseconds: 250),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bar_chart_outlined),
                          selectedIcon: Icon(Icons.bar_chart_rounded),
                          label: 'Data',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.print_outlined),
                          selectedIcon: Icon(Icons.print_rounded),
                          label: 'Printer',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings_rounded),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    ); // end PopScope
  }
}
