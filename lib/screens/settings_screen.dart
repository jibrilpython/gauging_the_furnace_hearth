import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/models/project_model.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _leftIndex = 0;
  int _rightIndex = 1;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;
    final canCompare = entries.length >= 2;

    if (entries.isNotEmpty) {
      _leftIndex = _leftIndex.clamp(0, entries.length - 1);
      _rightIndex = _rightIndex.clamp(0, entries.length - 1);
      if (canCompare && _leftIndex == _rightIndex) {
        _rightIndex = (_leftIndex + 1) % entries.length;
      }
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24.h,
              bottom: 16.h,
            ),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPARISON BENCH',
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Gauge Two\nInstruments',
                      style: GoogleFonts.playfairDisplay(
                        color: kPrimaryText,
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w700,
                        height: 0.98,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Place two pyrometric instruments on the bench and inspect where system, formulation, deformation temperature, and hearth provenance diverge.',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 140.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                canCompare
                    ? [
                        _selectors(entries),
                        SizedBox(height: 14.h),
                        _scoreCard(entries[_leftIndex], entries[_rightIndex]),
                        SizedBox(height: 14.h),
                        _comparisonRows(
                          entries[_leftIndex],
                          entries[_rightIndex],
                        ),
                      ]
                    : [_emptyState(entries.length)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectors(List<ThermalInstrumentModel> entries) {
    final left = entries[_leftIndex];
    final right = entries[_rightIndex];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _instrumentSelector('BENCH A', left, entries, true),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _instrumentSelector('BENCH B', right, entries, false),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                Icons.swap_horiz_rounded,
                'SWAP POSITIONS',
                () => setState(() {
                  final nextLeft = _rightIndex;
                  _rightIndex = _leftIndex;
                  _leftIndex = nextLeft;
                }),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _actionButton(
                Icons.open_in_new_rounded,
                'OPEN BENCH A',
                () => Navigator.pushNamed(
                  context,
                  '/info_screen',
                  arguments: {'index': _leftIndex},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _instrumentSelector(
    String label,
    ThermalInstrumentModel entry,
    List<ThermalInstrumentModel> entries,
    bool isLeft,
  ) {
    final color = getSystemColor(entry.pyrometricSystem);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 7.w),
              Text(
                label,
                style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryText,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: isLeft ? _leftIndex : _rightIndex,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
              dropdownColor: kPanelBg,
              borderRadius: BorderRadius.circular(kRadiusSubtle),
              selectedItemBuilder: (_) => entries
                  .map(
                    (e) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        e.smeltingHearthComplex.trim().isEmpty
                            ? e.pyrometricSystem.label
                            : e.smeltingHearthComplex,
                        style: GoogleFonts.playfairDisplay(
                          color: kPrimaryText,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              items: List.generate(
                entries.length,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    entries[index].thermalConeMatrixId,
                    style: GoogleFonts.ibmPlexMono(
                      color: kPrimaryText,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  if (isLeft) {
                    _leftIndex = value;
                    if (_leftIndex == _rightIndex) {
                      _rightIndex = (_leftIndex + 1) % entries.length;
                    }
                  } else {
                    _rightIndex = value;
                    if (_leftIndex == _rightIndex) {
                      _leftIndex = (_rightIndex + 1) % entries.length;
                    }
                  }
                });
              },
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            entry.thermalConeMatrixId,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 8.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        child: Ink(
          height: 44.h,
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17.sp),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(ThermalInstrumentModel left, ThermalInstrumentModel right) {
    final score = _compatibilityScore(left, right);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72.w,
            height: 72.w,
            child: CustomPaint(
              painter: _CompatibilityGaugePainter(score / 100),
              child: Center(
                child: Text(
                  '$score%',
                  style: GoogleFonts.ibmPlexMono(
                    color: kPrimaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CROSS-SYSTEM COMPATIBILITY',
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _scoreMessage(score),
                  style: GoogleFonts.playfairDisplay(
                    color: kPrimaryText,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'System · formulation · slag · status · hearth',
                  style: GoogleFonts.inter(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRows(
    ThermalInstrumentModel left,
    ThermalInstrumentModel right,
  ) {
    final rows = [
      _CompareRow(
        'System',
        left.pyrometricSystem.label,
        right.pyrometricSystem.label,
      ),
      _CompareRow(
        'Formulation',
        left.coneMineralFormulation.label,
        right.coneMineralFormulation.label,
      ),
      _CompareRow(
        'Deformation temp',
        left.deformationTemperatureTarget,
        right.deformationTemperatureTarget,
      ),
      _CompareRow(
        'Filament resistance',
        left.filamentLampResistance,
        right.filamentLampResistance,
      ),
      _CompareRow(
        'Filter density',
        left.filterGlassDensity,
        right.filterGlassDensity,
      ),
      _CompareRow(
        'Wedgwood coeff',
        left.wedgwoodExpansionCoefficient,
        right.wedgwoodExpansionCoefficient,
      ),
      _CompareRow(
        'Slag color',
        left.slagColorIndex.label,
        right.slagColorIndex.label,
      ),
      _CompareRow(
        'Thread pitch',
        left.sightTubeThreadPitch.label,
        right.sightTubeThreadPitch.label,
      ),
      _CompareRow(
        'Hearth',
        left.smeltingHearthComplex,
        right.smeltingHearthComplex,
      ),
      _CompareRow(
        'Status',
        left.deformationStatus.label,
        right.deformationStatus.label,
      ),
      _CompareRow('Era', left.era, right.era),
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(children: rows.map(_comparisonRow).toList()),
    );
  }

  Widget _comparisonRow(_CompareRow row) {
    final same = row.left == row.right && row.left.isNotEmpty;
    final color = same ? kSecondaryAccent : kAccent;
    final surface = same ? kBlueSurface : kOrangeSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                same
                    ? Icons.check_circle_rounded
                    : Icons.compare_arrows_rounded,
                color: color,
                size: 15.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                row.label.toUpperCase(),
                style: GoogleFonts.ibmPlexMono(
                  color: color,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _valueBlock(row.left)),
              SizedBox(width: 8.w),
              Expanded(child: _valueBlock(row.right)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueBlock(String text) {
    return Text(
      text.isEmpty ? 'Not recorded' : text,
      style: GoogleFonts.inter(
        color: text.isEmpty
            ? kSecondaryText.withValues(alpha: 0.55)
            : kPrimaryText,
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _emptyState(int count) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        children: [
          Icon(Icons.compare_arrows_rounded, color: kAccent, size: 42.sp),
          SizedBox(height: 14.h),
          Text(
            count == 0
                ? 'NO INSTRUMENTS IN THIS ARCHIVE.'
                : 'ADD ONE MORE INSTRUMENT.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexMono(
              color: kPrimaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'The comparison bench needs at least two catalogued pyrometric instruments before it can calculate cross-system compatibility.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  int _compatibilityScore(
    ThermalInstrumentModel left,
    ThermalInstrumentModel right,
  ) {
    double score = 0;
    const weight = 20.0;

    if (left.pyrometricSystem == right.pyrometricSystem) score += weight;
    if (left.coneMineralFormulation == right.coneMineralFormulation) {
      score += weight;
    }
    if (left.slagColorIndex == right.slagColorIndex) score += weight;
    if (left.deformationStatus == right.deformationStatus) {
      score += weight;
    } else if (_statusFamily(left.deformationStatus) ==
        _statusFamily(right.deformationStatus)) {
      score += weight * 0.5;
    }

    final leftHearth = left.smeltingHearthComplex.trim().toLowerCase();
    final rightHearth = right.smeltingHearthComplex.trim().toLowerCase();
    if (leftHearth.isNotEmpty && leftHearth == rightHearth) {
      score += weight;
    }

    return score.round().clamp(0, 100);
  }

  String _statusFamily(DeformationModelStatus status) {
    switch (status) {
      case DeformationModelStatus.fullSlump:
      case DeformationModelStatus.partialSlump:
        return 'slumped';
      case DeformationModelStatus.upright:
        return 'upright';
      case DeformationModelStatus.requiresMeasurement:
        return 'pending';
    }
  }

  String _scoreMessage(int score) {
    if (score >= 80) return 'Near-identical kiln cousins';
    if (score >= 60) return 'Shared pyrometric lineage';
    if (score >= 40) return 'Partial thermal overlap';
    return 'Distinct kiln specimens';
  }
}

class _CompareRow {
  final String label;
  final String left;
  final String right;
  const _CompareRow(this.label, this.left, this.right);
}

class _CompatibilityGaugePainter extends CustomPainter {
  final double fraction;
  const _CompatibilityGaugePainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..color = kSecondaryAccent.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CompatibilityGaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
