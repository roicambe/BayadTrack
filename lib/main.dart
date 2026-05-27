import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/main_shell.dart';

/// App entry point.
///
/// We use `async` here so we can await [ThemeProvider.init()] which loads
/// the user's saved theme & font scale from SharedPreferences BEFORE the
/// first frame is drawn — preventing a flash of the wrong theme.
void main() async {
  // Required when using async in main() before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialise the theme provider (loads saved prefs from storage)
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    // ChangeNotifierProvider makes ThemeProvider available to every widget
    // in the tree via context.watch<ThemeProvider>() or context.read<ThemeProvider>()
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const BayadTrackApp(),
    ),
  );
}

class BayadTrackApp extends StatelessWidget {
  const BayadTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds this widget whenever ThemeProvider calls notifyListeners()
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'BayadTrack',
      debugShowCheckedModeBanner: false, // hides the red DEBUG banner

      // Light and dark themes are defined in AppTheme
      theme:     AppTheme.lightTheme(themeProvider.usePoppins),
      darkTheme: AppTheme.darkTheme(themeProvider.usePoppins),

      // ThemeMode comes from the provider — changes instantly when user taps
      themeMode: themeProvider.themeMode,

      // builder wraps every screen so MediaQuery carries the font scale.
      // We calculate a responsive scale factor based on screen width.
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final screenWidth = mediaQueryData.size.width;
        
        // Base design width is around 375 logical pixels
        // Clamp between 0.85 and 1.15 to prevent text from getting too large on wider phones
        final double scaleFactor = (screenWidth / 375.0).clamp(0.85, 1.15);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },

      home: const MainShell(),
    );
  }
}
