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

class _TabTransitionSwitcher extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> children;

  const _TabTransitionSwitcher({
    super.key,
    required this.selectedIndex,
    required this.children,
  });

  @override
  State<_TabTransitionSwitcher> createState() => _TabTransitionSwitcherState();
}

class _TabTransitionSwitcherState extends State<_TabTransitionSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideInAnimation;
  late Animation<Offset> _slideOutAnimation;
  
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Initialize animations so they are not null on first build (even though value is 1.0)
    _slideInAnimation = const AlwaysStoppedAnimation(Offset.zero);
    _slideOutAnimation = const AlwaysStoppedAnimation(Offset.zero);
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_TabTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      final bool isMovingRight = widget.selectedIndex > _currentIndex;
      _currentIndex = widget.selectedIndex;

      _slideInAnimation = Tween<Offset>(
        begin: Offset(isMovingRight ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _slideOutAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(isMovingRight ? -1.0 : 1.0, 0.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(widget.children.length, (index) {
            final isCurrent = index == _currentIndex;
            final isPrevious = index == _previousIndex;
            final isAnimating = _controller.isAnimating;

            if (isCurrent) {
              return SlideTransition(
                position: isAnimating ? _slideInAnimation : const AlwaysStoppedAnimation(Offset.zero),
                child: widget.children[index],
              );
            } else if (isPrevious && isAnimating) {
              return SlideTransition(
                position: _slideOutAnimation,
                child: widget.children[index],
              );
            } else {
              return Offstage(
                offstage: true,
                // Still use a TickerMode to disable animations on offstage widgets
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }
          }),
        );
      },
    );
  }
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // GlobalKey so we can call DataScreenState methods from here
  final _dataScreenKey = GlobalKey<DataScreenState>();

  // Share intent subscription handle (cancelled in dispose)
  StreamSubscription<List<SharedFile>>? _sharingSubscription;

  // The four main screens — order matches the navigation bar destinations below
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

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
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sharingSubscription?.cancel();
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
      resizeToAvoidBottomInset: false,
      extendBody: true, // allows body to scroll behind the floating nav bar

      body: Stack(
        children: [
          Positioned.fill(
            child: _TabTransitionSwitcher(
              selectedIndex: _selectedIndex,
              children: _screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              maintainBottomViewPadding: true,
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
                        _switchToTab(index);
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
