import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/providers/image_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final index = args['index'] as int;
    final project = ref.watch(projectProvider);

    if (index < 0 || index >= project.entries.length) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Text(
            'INSTRUMENT NOT FOUND.',
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    final entry = project.entries[index];
    final imagePath = ref.watch(imageProvider).getImagePath(entry.photoPath);
    final systemColor = getSystemColor(entry.pyrometricSystem);
    final statusColor = getDeformationColor(entry.deformationStatus);
    final hasPhoto = imagePath != null && File(imagePath).existsSync();
    final designation = coneDesignationBadge(
      entry.pyrometricSystem,
      entry.deformationTemperatureTarget,
    );

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.40,
            stretch: true,
            pinned: false,
            backgroundColor: kBackground,
            leadingWidth: 68.w,
            leading: _roundAction(
              Icons.arrow_back_rounded,
              () => Navigator.pop(context),
            ),
            actions: [
              _roundAction(
                Icons.delete_outline_rounded,
                () => _confirmDelete(context, ref, index),
              ),
              SizedBox(width: 8.w),
              _roundAction(Icons.edit_rounded, () {
                ref.read(projectProvider).fillInput(ref, index);
                Navigator.pushNamed(
                  context,
                  '/add_screen',
                  arguments: {'index': index, 'isEdit': true},
                );
              }),
              SizedBox(width: 16.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: hasPhoto
                  ? Hero(
                      tag: 'instrument-photo-$index',
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: kSelectedTint,
                      child: Center(
                        child: CustomPaint(
                          size: Size(180.w, 200.w),
                          painter: _ConeSilhouettePainter(
                            status: entry.deformationStatus,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kRadiusLarge),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20.w,
                28.h,
                20.w,
                MediaQuery.of(context).padding.bottom + 32.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _floatingTag(
                        entry.pyrometricSystem.label.toUpperCase(),
                        systemColor,
                        icon: getSystemIcon(entry.pyrometricSystem),
                      ),
                      _floatingTag(
                        entry.deformationStatus.label,
                        statusColor,
                      ),
                      _designationPill(designation),
                    ],
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    entry.smeltingHearthComplex.isEmpty
                        ? 'Unnamed hearth'
                        : entry.smeltingHearthComplex,
                    style: GoogleFonts.playfairDisplay(
                      color: kPrimaryText,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    entry.thermalConeMatrixId,
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _sectionHeader('PYROMETRIC IDENTITY'),
                  SizedBox(height: 12.h),
                  _floatingSpecCard(
                    icon: getSystemIcon(entry.pyrometricSystem),
                    eyebrow: 'PYROMETRIC SYSTEM',
                    value: entry.pyrometricSystem.label,
                    accent: systemColor,
                  ),
                  SizedBox(height: 12.h),
                  _floatingSpecCard(
                    icon: Icons.change_history_rounded,
                    eyebrow: 'CONE MINERAL FORMULATION',
                    value: entry.coneMineralFormulation.label,
                    accent: kAccent,
                  ),
                  SizedBox(height: 12.h),
                  _floatingSpecCard(
                    icon: Icons.thermostat_rounded,
                    eyebrow: 'DEFORMATION TEMPERATURE TARGET',
                    value: entry.deformationTemperatureTarget.isEmpty
                        ? '—'
                        : entry.deformationTemperatureTarget,
                    accent: kAccent,
                    mono: true,
                  ),
                  SizedBox(height: 12.h),
                  _floatingSpecCard(
                    icon: Icons.ssid_chart_rounded,
                    eyebrow: 'DEFORMATION STATUS',
                    value: entry.deformationStatus.label,
                    accent: statusColor,
                    mono: true,
                  ),
                  SizedBox(height: 28.h),
                  _sectionHeader('OPTICAL SPECS'),
                  _specRow(
                    'Filament Resistance',
                    entry.filamentLampResistance,
                    mono: true,
                  ),
                  _specRow(
                    'Filter Glass Density',
                    entry.filterGlassDensity,
                    mono: true,
                  ),
                  _specRow(
                    'Wedgwood Coefficient',
                    entry.wedgwoodExpansionCoefficient,
                    mono: true,
                  ),
                  _specRow('Slag Color Index', entry.slagColorIndex.label),
                  _specRow(
                    'Sight Tube Pitch',
                    entry.sightTubeThreadPitch.label,
                  ),
                  SizedBox(height: 28.h),
                  _sectionHeader('PROVENANCE'),
                  if (entry.era.isNotEmpty) _specRow('Era', entry.era),
                  _specRow(
                    'Hearth Complex',
                    entry.smeltingHearthComplex,
                  ),
                  if (entry.notes.isNotEmpty) ...[
                    SizedBox(height: 28.h),
                    _sectionHeader('NOTES'),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: kPanelBg,
                        borderRadius: BorderRadius.circular(kRadiusSubtle),
                        border: Border.all(color: kOutline),
                        boxShadow: const [kShadowSubtle],
                      ),
                      child: Text(
                        entry.notes,
                        style: GoogleFonts.inter(
                          color: kPrimaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w300,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          entry.tags.map((tag) => _tagChip(tag)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPanelBg.withValues(alpha: 0.82),
                border: Border.all(color: kOutline),
              ),
              child: Icon(icon, color: kPrimaryText, size: 20.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatingTag(String text, Color color, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12.sp),
            SizedBox(width: 5.w),
          ],
          Text(
            text,
            style: GoogleFonts.ibmPlexMono(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _designationPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: kOrangeSurface,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: kAccent.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          color: kAccent,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3.w, height: 14.h, color: kAccent),
        SizedBox(width: 10.w),
        Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            color: kPrimaryText,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _floatingSpecCard({
    required IconData icon,
    required String eyebrow,
    required String value,
    required Color accent,
    bool mono = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kRadiusSubtle),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: accent, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: GoogleFonts.ibmPlexMono(
                    color: accent,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  value,
                  style: mono
                      ? GoogleFonts.ibmPlexMono(
                          color: kPrimaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        )
                      : GoogleFonts.inter(
                          color: kPrimaryText,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, {bool mono = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(color: kOutline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 128.w,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: kSecondaryText,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: mono
                    ? GoogleFonts.ibmPlexMono(
                        color: kPrimaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: kBlueSurface,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(
          color: kSecondaryAccent.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          color: kSecondaryAccent,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusStandard),
          side: const BorderSide(color: kOutline),
        ),
        title: Text(
          'REMOVE FROM ARCHIVE?',
          style: GoogleFonts.playfairDisplay(
            color: kPrimaryText,
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        content: Text(
          'This thermal instrument record will be permanently deleted from the local kiln archive.',
          style: GoogleFonts.inter(
            color: kSecondaryText,
            fontSize: 13.sp,
            fontWeight: FontWeight.w300,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectProvider).deleteEntry(index);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'REMOVE',
              style: GoogleFonts.ibmPlexMono(
                color: kError,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConeSilhouettePainter extends CustomPainter {
  final DeformationModelStatus status;
  final Color color;

  _ConeSilhouettePainter({required this.status, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color.withValues(alpha: 0.88);
    final outline = Paint()
      ..color = kPrimaryText.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final basePaint = Paint()..color = kOutline;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final tipY = size.height * 0.12;
    final baseHalf = size.width * 0.28;

    double tipOffsetX = 0;
    double tipBend = 0;
    switch (status) {
      case DeformationModelStatus.upright:
        tipOffsetX = 0;
        tipBend = 0;
        break;
      case DeformationModelStatus.partialSlump:
        tipOffsetX = size.width * 0.12;
        tipBend = size.height * 0.08;
        break;
      case DeformationModelStatus.fullSlump:
        tipOffsetX = size.width * 0.28;
        tipBend = size.height * 0.18;
        break;
      case DeformationModelStatus.requiresMeasurement:
        tipOffsetX = size.width * 0.04;
        tipBend = size.height * 0.02;
        break;
    }

    final path = Path()
      ..moveTo(cx - baseHalf, baseY)
      ..lineTo(cx + baseHalf, baseY)
      ..quadraticBezierTo(
        cx + baseHalf * 0.55,
        (baseY + tipY) / 2,
        cx + tipOffsetX,
        tipY + tipBend,
      )
      ..quadraticBezierTo(
        cx - baseHalf * 0.55 + tipOffsetX * 0.3,
        (baseY + tipY) / 2 + tipBend * 0.4,
        cx - baseHalf,
        baseY,
      )
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, baseY + 6),
          width: baseHalf * 2.4,
          height: 10,
        ),
        const Radius.circular(3),
      ),
      basePaint,
    );

    // faint companion cones (unfired / approaching / slumped motif)
    final ghost = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void drawGhost(double ox, double bend) {
      final g = Path()
        ..moveTo(ox - 10, baseY - 8)
        ..lineTo(ox + 10, baseY - 8)
        ..lineTo(ox + bend, tipY + 40)
        ..close();
      canvas.drawPath(g, ghost);
    }

    drawGhost(size.width * 0.18, 0);
    drawGhost(size.width * 0.82, 8);

    // calibration tick marks
    final tick = Paint()
      ..color = kSecondaryAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = tipY + 28 + i * 28.0;
      canvas.drawLine(
        Offset(cx - baseHalf - 14, y),
        Offset(cx - baseHalf - 6, y),
        tick,
      );
    }

    // subtle arc suggesting deformation trajectory
    if (status == DeformationModelStatus.partialSlump ||
        status == DeformationModelStatus.fullSlump) {
      final arc = Paint()
        ..color = kAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(cx, tipY + tipBend + 36),
          radius: 22,
        ),
        -math.pi / 2,
        math.pi * 0.65,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConeSilhouettePainter oldDelegate) =>
      oldDelegate.status != status || oldDelegate.color != color;
}
