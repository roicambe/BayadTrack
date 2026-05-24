import 'package:flutter/material.dart';

/// Central color palette for BayadTrack.
/// All colors are defined here — never hardcode colors anywhere else.
abstract class AppColors {
  // ── E-Wallet Brand Colors ──────────────────────────────────────────────────
  static const Color gcash     = Color(0xFF007AFF); // GCash signature blue
  static const Color gcashDeep = Color(0xFF0056C7); // darker shade for gradients
  static const Color maya      = Color(0xFF00B96B); // Maya signature green
  static const Color mayaDeep  = Color(0xFF00884D); // darker shade for gradients

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF1C1C1E); // lighter dark background
  static const Color darkSurface = Color(0xFF2C2C2E); // lighter surface for cards, bottom bar
  static const Color darkCard    = Color(0xFF3A3A3C); // lighter elevated cards
  static const Color darkBorder  = Color(0xFF48484A); // lighter borders

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF4F6FA); // main scaffold background
  static const Color lightSurface = Color(0xFFFFFFFF); // cards, bottom bar
  static const Color lightCard    = Color(0xFFFFFFFF); // elevated cards
  static const Color lightBorder  = Color(0xFFE4E7F0); // subtle borders

  // ── Text Colors ────────────────────────────────────────────────────────────
  static const Color textPrimaryDark    = Color(0xFFF0F2F8); // headings in dark mode
  static const Color textSecondaryDark  = Color(0xFF8B90A7); // captions in dark mode
  static const Color textPrimaryLight   = Color(0xFF1A1D2E); // headings in light mode
  static const Color textSecondaryLight = Color(0xFF6B7280); // captions in light mode

  // ── Status Colors ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Data & Reports Action Colors ───────────────────────────────────────────
  static const Color excelGreen  = Color(0xFF1D6F42);
  static const Color pdfRed      = Color(0xFFE53935);
  static const Color backupBlue  = Color(0xFF5B5BD6);
}
