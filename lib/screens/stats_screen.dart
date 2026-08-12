import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/models/project_model.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _pressedMetric;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSheet(String title, List<Widget> children) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
          border: Border.all(color: kOutline),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: kOutline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: GoogleFonts.ibmPlexMono(
                  color: kPrimaryText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8.h),
              const Divider(color: kOutline),
              SizedBox(height: 8.h),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Map<T, int> _countBy<T>(
    List<ThermalInstrumentModel> entries,
    T Function(ThermalInstrumentModel) selector,
  ) {
    final map = <T, int>{};
    for (final e in entries) {
      final key = selector(e);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Color _slagHeat(SlagColorIndex index) {
    switch (index) {
      case SlagColorIndex.dullRed:
        return const Color(0xFF8B1A1A);
      case SlagColorIndex.cherryRed:
        return const Color(0xFFB03020);
      case SlagColorIndex.brightCherry:
        return kAccent;
      case SlagColorIndex.orangeYellow:
        return const Color(0xFFD4782A);
      case SlagColorIndex.whiteYellow:
        return const Color(0xFFE8A040);
      case SlagColorIndex.dazzlingWhite:
        return const Color(0xFFF0D080);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final entries = project.entries;

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LogbookGridPainter()),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildHeader(),
              if (project.isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    color: kAccent,
                    backgroundColor: kOutline,
                    minHeight: 2,
                  ),
                )
              else if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmpty(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 140.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildKeyMetrics(entries),
                      SizedBox(height: 24.h),
                      _sectionTitle('PYROMETRIC SYSTEM'),
                      SizedBox(height: 12.h),
                      _buildSystemDistribution(entries),
                      SizedBox(height: 24.h),
                      _sectionTitle('DEFORMATION STATUS'),
                      SizedBox(height: 12.h),
                      _buildDeformationBreakdown(entries),
                      SizedBox(height: 24.h),
                      _sectionTitle('SLAG COLOR HEATMAP'),
                      SizedBox(height: 12.h),
                      _buildSlagHeatmap(entries),
                      SizedBox(height: 24.h),
                      _sectionTitle('CONE FORMULATION'),
                      SizedBox(height: 12.h),
                      _buildFormulationCounts(entries),
                      SizedBox(height: 16.h),
                      _buildArchiveFooter(entries),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverPadding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 18.h,
        bottom: 10.h,
      ),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGBOOK',
                style: GoogleFonts.ibmPlexMono(
                  color: kAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Kiln Record\nMetrics',
                style: GoogleFonts.playfairDisplay(
                  color: kPrimaryText,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Archive pulse across pyrometric systems, cone deformation states, and slag colour indices.',
                style: GoogleFonts.inter(
                  color: kSecondaryText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size(72.w, 72.w),
            painter: _EmptyRingPainter(),
          ),
          SizedBox(height: 18.h),
          Text(
            'NO INSTRUMENTS IN THIS ARCHIVE.',
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Catalogue Seger cones, Wedgwood cylinders,\nor optical pyrometers to populate the logbook.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: kSecondaryText.withValues(alpha: 0.75),
              fontSize: 13.sp,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.ibmPlexMono(
            color: kSecondaryText,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: kSecondaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              color: kPrimaryText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(List<ThermalInstrumentModel> entries) {
    final total = entries.length;
    final measured = entries
        .where((e) => e.deformationStatus != DeformationModelStatus.requiresMeasurement)
        .length;
    final pending = total - measured;
    final measuredPct = total == 0 ? 0 : (measured / total * 100).round();
    final hearths = entries
        .map((e) => e.smeltingHearthComplex.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        return Row(
          children: [
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressedMetric = 0),
                onTapCancel: () => setState(() => _pressedMetric = null),
                onTapUp: (_) {
                  setState(() => _pressedMetric = null);
                  _showSheet('TOTAL INSTRUMENTS', [
                    _detailRow('Archive size', total.toString()),
                    _detailRow('Deformation measured', measured.toString()),
                    _detailRow('Awaiting measurement', pending.toString()),
                    _detailRow('Hearth complexes', hearths.toString()),
                    SizedBox(height: 10.h),
                    Text(
                      'Thermal cone matrices tracked across the kiln record archive.',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ]);
                },
                child: AnimatedScale(
                  scale: _pressedMetric == 0 ? 0.96 : 1,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    height: 132.h,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(kRadiusSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: kAccent.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 22.sp,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (total * t).round().toString().padLeft(2, '0'),
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 36.sp,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'TOTAL INSTRUMENTS',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 132.h,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _pressedMetric = 1),
                        onTapCancel: () =>
                            setState(() => _pressedMetric = null),
                        onTapUp: (_) {
                          setState(() => _pressedMetric = null);
                          _showSheet('DEFORMATION MEASURED', [
                            _detailRow('Measured records', measured.toString()),
                            _detailRow('Pending', pending.toString()),
                            _detailRow('Measured ratio', '$measuredPct%'),
                            SizedBox(height: 10.h),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(kRadiusPill),
                              child: SizedBox(
                                height: 10.h,
                                child: Row(
                                  children: [
                                    if (measured > 0)
                                      Expanded(
                                        flex: measured,
                                        child: Container(color: kAccent),
                                      ),
                                    if (pending > 0)
                                      Expanded(
                                        flex: pending,
                                        child: Container(
                                          color: kSecondaryAccent,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ]);
                        },
                        child: AnimatedScale(
                          scale: _pressedMetric == 1 ? 0.95 : 1,
                          duration: const Duration(milliseconds: 100),
                          child: _miniMetric(
                            'MEASURED',
                            '${(measuredPct * t).round()}%',
                            kAccent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _pressedMetric = 2),
                        onTapCancel: () =>
                            setState(() => _pressedMetric = null),
                        onTapUp: (_) {
                          setState(() => _pressedMetric = null);
                          _showSheet('HEARTH COMPLEXES', [
                            _detailRow('Unique complexes', hearths.toString()),
                            _detailRow('Instruments', total.toString()),
                            SizedBox(height: 8.h),
                            Text(
                              hearths == 0
                                  ? 'No smelting hearth complexes named yet.'
                                  : 'Distinct ironworks, porcelain kilns, and copper smelters in the archive.',
                              style: GoogleFonts.inter(
                                color: kSecondaryText,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ]);
                        },
                        child: AnimatedScale(
                          scale: _pressedMetric == 2 ? 0.95 : 1,
                          duration: const Duration(milliseconds: 100),
                          child: _miniMetric(
                            'HEARTHS',
                            (hearths * t).round().toString().padLeft(2, '0'),
                            kSecondaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniMetric(String label, String value, Color accent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.playfairDisplay(
                color: accent,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemDistribution(List<ThermalInstrumentModel> entries) {
    final counts = _countBy(entries, (e) => e.pyrometricSystem);
    final total = entries.length;
    final systems = PyrometricSystem.values
        .where((s) => (counts[s] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            border: Border.all(color: kOutline),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 120.w,
                child: Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      height: 120.w,
                      child: CustomPaint(
                        painter: _SystemRingPainter(
                          counts: {
                            for (final s in systems)
                              s: (counts[s] ?? 0) / total * _animation.value,
                          },
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${systems.length}',
                                style: GoogleFonts.playfairDisplay(
                                  color: kPrimaryText,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'SYSTEMS',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kSecondaryText,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        children: [
                          for (final system in systems)
                            GestureDetector(
                              onTap: () {
                                final list = entries
                                    .where((e) => e.pyrometricSystem == system)
                                    .toList();
                                _showSheet(
                                  system.label.toUpperCase(),
                                  [
                                    _detailRow(
                                      'Count',
                                      list.length.toString(),
                                    ),
                                    _detailRow(
                                      'Share',
                                      '${(list.length / total * 100).round()}%',
                                    ),
                                    _detailRow(
                                      'Authority index',
                                      getSystemAuthority(system)
                                          .toStringAsFixed(2),
                                    ),
                                    _detailRow('Code', systemCode(system)),
                                    SizedBox(height: 10.h),
                                    ...list.take(8).map(
                                          (e) => Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 8.h),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  getSystemIcon(system),
                                                  color:
                                                      getSystemColor(system),
                                                  size: 14.sp,
                                                ),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: Text(
                                                    e.thermalConeMatrixId,
                                                    style:
                                                        GoogleFonts.ibmPlexMono(
                                                      color: kPrimaryText,
                                                      fontSize: 11.sp,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    if (list.length > 8)
                                      Text(
                                        '+${list.length - 8} more',
                                        style: GoogleFonts.inter(
                                          color: kSecondaryText,
                                          fontSize: 11.sp,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        color: getSystemColor(system),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        system.label,
                                        style: GoogleFonts.inter(
                                          color: kPrimaryText,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${counts[system]}',
                                      style: GoogleFonts.ibmPlexMono(
                                        color: getSystemColor(system),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              for (final system in systems)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusPill),
                        child: SizedBox(
                          height: 6.h,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: ((counts[system] ?? 0) / total) *
                                _animation.value,
                            child: Container(color: getSystemColor(system)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeformationBreakdown(List<ThermalInstrumentModel> entries) {
    final counts = _countBy(entries, (e) => e.deformationStatus);
    final total = entries.length;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            border: Border.all(color: kOutline),
          ),
          child: Column(
            children: [
              for (final status in DeformationModelStatus.values) ...[
                GestureDetector(
                  onTap: () {
                    final list = entries
                        .where((e) => e.deformationStatus == status)
                        .toList();
                    _showSheet(status.label, [
                      _detailRow('Count', list.length.toString()),
                      _detailRow(
                        'Share',
                        total == 0
                            ? '0%'
                            : '${(list.length / total * 100).round()}%',
                      ),
                      SizedBox(height: 8.h),
                      ...list.take(8).map(
                            (e) => Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                '${e.thermalConeMatrixId}  ·  ${e.deformationTemperatureTarget.isEmpty ? '—' : e.deformationTemperatureTarget}',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kPrimaryText,
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ]);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                status.label,
                                style: GoogleFonts.ibmPlexMono(
                                  color: kPrimaryText,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${counts[status] ?? 0}',
                              style: GoogleFonts.ibmPlexMono(
                                color: getDeformationColor(status),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(kRadiusPill),
                          child: LinearProgressIndicator(
                            value: total == 0
                                ? 0
                                : ((counts[status] ?? 0) / total) *
                                    _animation.value,
                            minHeight: 8.h,
                            backgroundColor: kOutline.withValues(alpha: 0.55),
                            color: getDeformationColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlagHeatmap(List<ThermalInstrumentModel> entries) {
    final counts = _countBy(entries, (e) => e.slagColorIndex);
    final maxCount = counts.values.fold<int>(0, math.max);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            border: Border.all(color: kOutline),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: SlagColorIndex.values.map((slag) {
              final count = counts[slag] ?? 0;
              final intensity = maxCount == 0
                  ? 0.15
                  : (0.22 + 0.78 * (count / maxCount) * _animation.value);
              final heat = _slagHeat(slag);
              return GestureDetector(
                onTap: () {
                  final list =
                      entries.where((e) => e.slagColorIndex == slag).toList();
                  _showSheet(slag.label.toUpperCase(), [
                    _detailRow('Count', list.length.toString()),
                    SizedBox(height: 8.h),
                    Text(
                      'Optical match band used for disappearing-filament and radiation pyrometer cross-checks.',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...list.take(6).map(
                          (e) => Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Text(
                              e.thermalConeMatrixId,
                              style: GoogleFonts.ibmPlexMono(
                                color: kPrimaryText,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ),
                  ]);
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: heat.withValues(alpha: intensity.clamp(0.15, 1.0)),
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    border: Border.all(
                      color: heat.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slag.label.split(' / ').first,
                        style: GoogleFonts.inter(
                          color: count > maxCount * 0.45
                              ? Colors.white
                              : kPrimaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'n=${count.toString().padLeft(2, '0')}',
                        style: GoogleFonts.ibmPlexMono(
                          color: count > maxCount * 0.45
                              ? Colors.white.withValues(alpha: 0.85)
                              : kSecondaryText,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFormulationCounts(List<ThermalInstrumentModel> entries) {
    final counts = _countBy(entries, (e) => e.coneMineralFormulation);
    final total = entries.length;
    final forms = ConeMineralFormulation.values
        .where((f) => (counts[f] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            border: Border.all(color: kOutline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < forms.length; i++) ...[
                GestureDetector(
                  onTap: () {
                    final form = forms[i];
                    final list = entries
                        .where((e) => e.coneMineralFormulation == form)
                        .toList();
                    _showSheet(form.label.toUpperCase(), [
                      _detailRow('Count', list.length.toString()),
                      _detailRow(
                        'Share',
                        '${(list.length / total * 100).round()}%',
                      ),
                      SizedBox(height: 8.h),
                      ...list.take(8).map(
                            (e) => Padding(
                              padding: EdgeInsets.only(bottom: 6.h),
                              child: Text(
                                e.thermalConeMatrixId,
                                style: GoogleFonts.ibmPlexMono(
                                  color: kPrimaryText,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                    ]);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i.isEven ? kOrangeSurface : kBlueSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kOutline),
                          ),
                          child: Text(
                            '${counts[forms[i]]}',
                            style: GoogleFonts.ibmPlexMono(
                              color: i.isEven ? kAccent : kSecondaryAccent,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            forms[i].label,
                            style: GoogleFonts.inter(
                              color: kPrimaryText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          total == 0
                              ? '0%'
                              : '${(((counts[forms[i]] ?? 0) / total) * 100 * _animation.value).round()}%',
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchiveFooter(List<ThermalInstrumentModel> entries) {
    final eras = entries
        .map((e) => e.era.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kSelectedTint,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARCHIVE FOOTNOTE',
            style: GoogleFonts.ibmPlexMono(
              color: kAccent,
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${entries.length} instruments · $eras era labels · deformation evidence read in laboratory light.',
            style: GoogleFonts.inter(
              color: kPrimaryText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w300,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogbookGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutline.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 0.35,
      false,
      Paint()
        ..color = kAccent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SystemRingPainter extends CustomPainter {
  final Map<PyrometricSystem, double> counts;
  const _SystemRingPainter({required this.counts});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..color = kOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, track);

    var start = -math.pi / 2;
    for (final entry in counts.entries) {
      final sweep = entry.value * math.pi * 2;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = getSystemColor(entry.key)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SystemRingPainter oldDelegate) =>
      oldDelegate.counts != counts;
}
