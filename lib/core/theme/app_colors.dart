import 'package:flutter/material.dart';

/// Bảng màu chính cho ứng dụng SafeWheels.
/// Hỗ trợ cả Light và Dark mode.
class AppColors {
  AppColors._();

  // Primary 
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);

  // Dark Theme 
  static const Color darkBackground = Color(0xFF0F1120);
  static const Color darkSurface = Color(0xFF1A1D2E);
  static const Color darkCard = Color(0xFF232740);
  static const Color darkInputFill = Color(0xFF1E2235);
  static const Color darkBorder = Color(0xFF2A2E45);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextHint = Color(0xFF6B7080);

  // Light Theme 
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F2F5);
  static const Color lightInputFill = Color(0xFFF0F2F5);
  static const Color lightBorder = Color(0xFFDDE1E8);
  static const Color lightTextPrimary = Color(0xFF1A1D2E);
  static const Color lightTextSecondary = Color(0xFF6B7080);
  static const Color lightTextHint = Color(0xFF9CA3B0);

  // Status 
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);

  // Notification Categories 
  static const Color notifBus = Color(0xFF3B82F6);
  static const Color notifSuccess = Color(0xFF22C55E);
  static const Color notifFeedback = Color(0xFFF97316);
  static const Color notifSystem = Color(0xFF8B5CF6);
}
