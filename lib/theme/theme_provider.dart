import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider manages two global settings:
///   1. ThemeMode  — System / Light / Dark
///   2. fontScale  — 1.0 (Normal) / 1.2 (Large) / 1.4 (Extra Large)
///
/// Both values are persisted using SharedPreferences so they survive
/// app restarts. Call [init()] once before runApp() to restore them.
class ThemeProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const _kThemeMode = 'bt_theme_mode'; // stores ThemeMode.index (0/1/2)
  static const _kFontScale = 'bt_font_scale'; // stores double
  static const _kUsePoppins = 'bt_use_poppins'; // stores bool

  ThemeMode _themeMode = ThemeMode.system;
  double    _fontScale  = 1.0;
  bool      _usePoppins = true;

  // ── Getters ─────────────────────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  double    get fontScale => _fontScale;
  bool      get usePoppins => _usePoppins;

  // ── init: call once at startup (before runApp) ───────────────────────────────
  /// Loads persisted values from SharedPreferences.
  /// Must be awaited so the app starts with the correct theme.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // ThemeMode.values = [system(0), light(1), dark(2)]
    _themeMode = ThemeMode.values[prefs.getInt(_kThemeMode) ?? 0];
    _fontScale  = prefs.getDouble(_kFontScale) ?? 1.0;
    _usePoppins = prefs.getBool(_kUsePoppins) ?? true;
    // No notifyListeners() needed here — the widget tree isn't built yet
  }

  // ── Theme Mode ───────────────────────────────────────────────────────────────
  /// Switch between System, Light, and Dark modes.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // no-op if already set
    _themeMode = mode;
    notifyListeners(); // rebuild the MaterialApp immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  // ── Font Scale ───────────────────────────────────────────────────────────────
  /// Available font scales:
  ///   1.0 → A   (Normal)
  ///   1.2 → A+  (Large)
  ///   1.4 → A++ (Extra Large)
  Future<void> setFontScale(double scale) async {
    if (_fontScale == scale) return;
    _fontScale = scale;
    notifyListeners(); // all Text widgets re-render instantly via MediaQuery
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontScale, scale);
  }

  // ── Font Family ──────────────────────────────────────────────────────────────
  /// Switch between Poppins and System Font
  Future<void> setUsePoppins(bool value) async {
    if (_usePoppins == value) return;
    _usePoppins = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUsePoppins, value);
  }

  // ── Convenience helpers ───────────────────────────────────────────────────────
  bool get isLight  => _themeMode == ThemeMode.light;
  bool get isDark   => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;
}
