import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand Palette (exact values from design spec) ──────────────────────────
  static const Color primary        = Color(0xFF1E3A5F); // Deep Navy
  static const Color primaryLight   = Color(0xFF2B4A70); // Secondary Navy (lighter)
  static const Color primaryDark    = Color(0xFF122438); // Darkest Navy
  static const Color secondary      = Color(0xFFF5A623); // Accent Gold
  static const Color secondaryLight = Color(0xFFFFBD45); // Light Gold

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static const Color backgroundLight    = Color(0xFFF8F9FA); // #F8F9FA
  static const Color surfaceLight       = Color(0xFFFFFFFF); // #FFFFFF
  static const Color cardLight          = Color(0xFFFFFFFF);
  static const Color textPrimaryLight   = Color(0xFF1C1C1C); // #1C1C1C
  static const Color textSecondaryLight = Color(0xFF5A6D82);
  static const Color borderLight        = Color(0xFFDDE3EA);
  static const Color dividerLight       = Color(0xFFEEF1F5);

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static const Color backgroundDark    = Color(0xFF0E1E30);
  static const Color surfaceDark       = Color(0xFF1A2D42);
  static const Color cardDark          = Color(0xFF1A2D42);
  static const Color textPrimaryDark   = Color(0xFFF0F4F8);
  static const Color textSecondaryDark = Color(0xFF8FA8C0);
  static const Color borderDark        = Color(0xFF2A4060);
  static const Color dividerDark       = Color(0xFF1A2D42);

  // ── Status & Feedback ────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFD32F2F); // #D32F2F — exact from spec
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF2563EB);

  // ── E-commerce Tokens ────────────────────────────────────────────────────────
  static const Color ratingStar            = Color(0xFFF5A623);
  static const Color priceTag              = Color(0xFF1E3A5F);
  static const Color discountBadge         = Color(0xFFD32F2F);
  static const Color shimmerBaseLight      = Color(0xFFDDE3EA);
  static const Color shimmerHighlightLight = Color(0xFFEEF1F5);
  static const Color shimmerBaseDark       = Color(0xFF2A4060);
  static const Color shimmerHighlightDark  = Color(0xFF3A5070);
}
