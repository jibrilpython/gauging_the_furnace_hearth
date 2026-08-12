import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';

const Color kBackground = Color(0xFFF7F4EF);
const Color kPrimaryText = Color(0xFF1A1510);
const Color kPanelBg = Color(0xFFFFFFFF);
const Color kSecondaryText = Color(0xFF7A7268);
const Color kAccent = Color(0xFFB5420A);
const Color kSecondaryAccent = Color(0xFF4A6A8A);
const Color kOutline = Color(0xFFE8E2D8);
const Color kError = Color(0xFFC0392B);
const Color kSelectedTint = Color(0xFFFBF0E8);
const Color kSimPanel = Color(0xFFF0EAE0);
const Color kBlueSurface = Color(0xFFE8EEF4);
const Color kOrangeSurface = Color(0xFFF8E8DE);

const double kRadiusSubtle = 10;
const double kRadiusStandard = 16;
const double kRadiusMedium = 24;
const double kRadiusLarge = 32;
const double kRadiusPill = 999;

const BoxShadow kShadowSubtle = BoxShadow(
  offset: Offset(0, 4),
  blurRadius: 16,
  spreadRadius: -4,
  color: Color(0x14000000),
);

const BoxShadow kShadowFloat = BoxShadow(
  offset: Offset(0, 12),
  blurRadius: 28,
  spreadRadius: -12,
  color: Color(0x1A000000),
);

const double kBottomNavBarHeight = 68;
const double kBottomNavBarMargin = 16;
const double kAddButtonGapAboveNav = 12;

double bottomNavOverlayHeight(BuildContext context) {
  return MediaQuery.of(context).padding.bottom +
      kBottomNavBarMargin.h +
      kBottomNavBarHeight.h;
}

double homeAddButtonBottom(BuildContext context) {
  return bottomNavOverlayHeight(context) + kAddButtonGapAboveNav.h;
}

Color getSystemColor(PyrometricSystem system) {
  switch (system) {
    case PyrometricSystem.segerCone:
      return kAccent;
    case PyrometricSystem.ortonCone:
      return const Color(0xFFC45A1A);
    case PyrometricSystem.wedgwoodCylinder:
      return kSecondaryAccent;
    case PyrometricSystem.disappearingFilament:
      return const Color(0xFF6A5A8A);
    case PyrometricSystem.radiationPyrometer:
      return const Color(0xFF8A5A4A);
    case PyrometricSystem.thermocoupleKit:
      return const Color(0xFF5A7A6A);
  }
}

Color getDeformationColor(DeformationModelStatus status) {
  switch (status) {
    case DeformationModelStatus.fullSlump:
      return kAccent;
    case DeformationModelStatus.partialSlump:
      return const Color(0xFFC9A050);
    case DeformationModelStatus.upright:
      return kSecondaryAccent;
    case DeformationModelStatus.requiresMeasurement:
      return kSecondaryText;
  }
}

double getSystemAuthority(PyrometricSystem system) {
  switch (system) {
    case PyrometricSystem.segerCone:
      return 1.0;
    case PyrometricSystem.ortonCone:
      return 0.88;
    case PyrometricSystem.disappearingFilament:
      return 0.76;
    case PyrometricSystem.wedgwoodCylinder:
      return 0.62;
    case PyrometricSystem.radiationPyrometer:
      return 0.48;
    case PyrometricSystem.thermocoupleKit:
      return 0.34;
  }
}

IconData getSystemIcon(PyrometricSystem system) {
  switch (system) {
    case PyrometricSystem.segerCone:
    case PyrometricSystem.ortonCone:
      return Icons.change_history_rounded;
    case PyrometricSystem.wedgwoodCylinder:
      return Icons.straighten_rounded;
    case PyrometricSystem.disappearingFilament:
      return Icons.visibility_rounded;
    case PyrometricSystem.radiationPyrometer:
      return Icons.wb_sunny_outlined;
    case PyrometricSystem.thermocoupleKit:
      return Icons.thermostat_rounded;
  }
}

String systemCode(PyrometricSystem system) {
  switch (system) {
    case PyrometricSystem.segerCone:
      return 'SEGER';
    case PyrometricSystem.ortonCone:
      return 'ORTON';
    case PyrometricSystem.wedgwoodCylinder:
      return 'WED';
    case PyrometricSystem.disappearingFilament:
      return 'FIL';
    case PyrometricSystem.radiationPyrometer:
      return 'RAD';
    case PyrometricSystem.thermocoupleKit:
      return 'TC';
  }
}

String coneDesignationBadge(
  PyrometricSystem system,
  String deformationTarget,
) {
  final code = systemCode(system);
  final temp = deformationTarget.isEmpty ? '—' : deformationTarget;
  return '$code / $temp';
}

Color thermalColorForProgress(double t) {
  // t: 0..1 from cool to hot
  if (t < 0.33) {
    return Color.lerp(const Color(0xFF8B1A1A), const Color(0xFFC45A1A), t / 0.33)!;
  }
  if (t < 0.66) {
    return Color.lerp(const Color(0xFFC45A1A), kAccent, (t - 0.33) / 0.33)!;
  }
  return Color.lerp(kAccent, const Color(0xFFE8A040), (t - 0.66) / 0.34)!;
}
