import 'package:echo_bloom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Typography definitions strictly matching reference font weights and colors.
abstract final class AppTypography {
  static const TextStyle headerTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textNavy,
    letterSpacing: -0.2,
  );

  static const TextStyle trackTitle = TextStyle(
    fontSize: 23.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textNavy,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle artistName = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPurple,
    letterSpacing: -0.1,
  );

  static const TextStyle timeProgress = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textNavy,
    letterSpacing: -0.2,
  );

  static const TextStyle navLabelActive = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryPurple,
    letterSpacing: -0.2,
  );

  static const TextStyle navLabelInactive = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.iconMuted,
    letterSpacing: -0.2,
  );
}

