import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/models/project_model.dart';
import 'package:gauging_the_furnace_hearth/providers/image_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/input_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/search_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  PyrometricSystem? _selectedSystem;
  bool _isBtnPressed = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final search = ref.watch(searchProvider);
    final allEntries = project.entries;
    final entries = search
        .filteredList(allEntries)
        .where(
          (e) => _selectedSystem == null || e.pyrometricSystem == _selectedSystem,
        )
        .toList();
    final addButtonBottom = homeAddButtonBottom(context);
    final listBottomPad = addButtonBottom + 56.h;

    return Scaffold(
      backgroundColor: kBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _header(allEntries.length),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      _searchBar(),
                      SizedBox(height: 14.h),
                      _systemChips(),
                      SizedBox(height: 22.h),
                    ],
                  ),
                ),
              ),
              if (project.isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    color: kAccent,
                    backgroundColor: kOutline,
                    minHeight: 2,
                  ),
                )
              else if (entries.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverList.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _InstrumentCard(
                        entry: entry,
                        index: allEntries.indexOf(entry),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: listBottomPad)),
            ],
          ),
          Positioned(
            right: 20.w,
            bottom: addButtonBottom,
            child: _addButton(),
          ),
        ],
      ),
    );
  }

  Widget _header(int count) {
    const gap = 12.0;
    return SliverPadding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 18.h,
        bottom: gap.h,
      ),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'KILN RECORD ARCHIVE',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      border: Border.all(color: kOutline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          count.toString().padLeft(2, '0'),
                          style: GoogleFonts.ibmPlexMono(
                            color: kAccent,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          count == 1 ? 'RECORD' : 'RECORDS',
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
                ],
              ),
              SizedBox(height: gap.h),
              Text(
                'Gauging the',
                style: GoogleFonts.inter(
                  color: kSecondaryText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Furnace Hearth',
                style: GoogleFonts.playfairDisplay(
                  color: kPrimaryText,
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: gap.h),
              Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Seger cones · Wedgwood cylinders · optical pyrometers',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    final focused = _searchFocusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(
          color: focused ? kAccent : kOutline,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) => ref.read(searchProvider).setSearchQuery(v),
        style: GoogleFonts.inter(color: kPrimaryText, fontSize: 14.sp),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintText: 'Search matrix ID, hearth, cone…',
          prefixIcon: Icon(Icons.search_rounded, color: kSecondaryText, size: 20.sp),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: kSecondaryText, size: 18.sp),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider).clearSearchQuery();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _systemChips() {
    return SizedBox(
      height: 36.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(null, 'All systems'),
          ...PyrometricSystem.values.map((s) => _chip(s, s.label)),
        ],
      ),
    );
  }

  Widget _chip(PyrometricSystem? system, String label) {
    final selected = _selectedSystem == system;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSystem = system),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kAccent : kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusPill),
            border: Border.all(color: selected ? kAccent : kOutline),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexMono(
              color: selected ? Colors.white : kSecondaryText,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'NO INSTRUMENTS IN THIS ARCHIVE.',
        style: GoogleFonts.ibmPlexMono(
          color: kSecondaryText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isBtnPressed = true),
      onTapUp: (_) => setState(() => _isBtnPressed = false),
      onTapCancel: () => setState(() => _isBtnPressed = false),
      onTap: () {
        ref.read(inputProvider).clearAll();
        ref.read(imageProvider).clearImage();
        Navigator.pushNamed(context, '/add_screen');
      },
      child: AnimatedScale(
        scale: _isBtnPressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(kRadiusPill),
            boxShadow: [
              BoxShadow(
                color: kAccent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
        ),
      ),
    );
  }
}

class _InstrumentCard extends ConsumerWidget {
  final ThermalInstrumentModel entry;
  final int index;
  const _InstrumentCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = ref.watch(imageProvider).getImagePath(entry.photoPath);
    final hasPhoto = imagePath != null && File(imagePath).existsSync();
    final systemColor = getSystemColor(entry.pyrometricSystem);
    final statusColor = getDeformationColor(entry.deformationStatus);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/info_screen',
            arguments: {'index': index},
          ),
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          child: Ink(
            decoration: BoxDecoration(
              color: kPanelBg,
              borderRadius: BorderRadius.circular(kRadiusSubtle),
              border: const Border(
                left: BorderSide(color: kAccent, width: 3),
                top: BorderSide(color: kAccent, width: 1),
                right: BorderSide(color: kAccent, width: 1),
                bottom: BorderSide(color: kAccent, width: 1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasPhoto)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagePath),
                            width: 52.w,
                            height: 52.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 52.w,
                          height: 52.w,
                          decoration: BoxDecoration(
                            color: kSelectedTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kOutline),
                          ),
                          child: CustomPaint(
                            painter: _MiniConePainter(
                              status: entry.deformationStatus,
                              color: systemColor,
                            ),
                          ),
                        ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.thermalConeMatrixId,
                              style: GoogleFonts.ibmPlexMono(
                                color: kPrimaryText,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              entry.smeltingHearthComplex.isEmpty
                                  ? entry.pyrometricSystem.label
                                  : entry.smeltingHearthComplex,
                              style: GoogleFonts.playfairDisplay(
                                color: kPrimaryText,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 28.h,
                    child: CustomPaint(
                      size: Size(double.infinity, 28.h),
                      painter: _ConeSequenceStripPainter(
                        highlighted: entry.deformationStatus,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      _pill(
                        coneDesignationBadge(
                          entry.pyrometricSystem,
                          entry.deformationTemperatureTarget,
                        ),
                        kAccent,
                      ),
                      _pill(
                        entry.deformationStatus.label,
                        statusColor,
                      ),
                      if (entry.smeltingHearthComplex.isNotEmpty)
                        _pill(
                          entry.smeltingHearthComplex,
                          kSecondaryAccent,
                          fill: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, {bool fill = false}) {
    return Container(
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: fill ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          color: color,
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.35,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

class _MiniConePainter extends CustomPainter {
  final DeformationModelStatus status;
  final Color color;
  _MiniConePainter({required this.status, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bend = switch (status) {
      DeformationModelStatus.upright => 0.0,
      DeformationModelStatus.partialSlump => 0.45,
      DeformationModelStatus.fullSlump => 1.0,
      DeformationModelStatus.requiresMeasurement => 0.2,
    };
    final base = Offset(size.width * 0.5, size.height * 0.82);
    final h = size.height * 0.6;
    final tipX = base.dx + bend * h * 0.5;
    final tipY = base.dy - h + bend * h * 0.12;
    final path = Path()
      ..moveTo(base.dx - h * 0.22, base.dy)
      ..lineTo(tipX, tipY)
      ..lineTo(base.dx + h * 0.22, base.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiniConePainter old) =>
      old.status != status || old.color != color;
}

class _ConeSequenceStripPainter extends CustomPainter {
  final DeformationModelStatus highlighted;
  _ConeSequenceStripPainter({required this.highlighted});

  @override
  void paint(Canvas canvas, Size size) {
    final bends = [0.0, 0.45, 1.0];
    final labels = [
      DeformationModelStatus.upright,
      DeformationModelStatus.partialSlump,
      DeformationModelStatus.fullSlump,
    ];
    for (var i = 0; i < 3; i++) {
      final cx = size.width * (0.18 + i * 0.32);
      final active = labels[i] == highlighted ||
          (highlighted == DeformationModelStatus.requiresMeasurement && i == 0);
      final color = active ? kAccent : kPrimaryText.withValues(alpha: 0.25);
      final base = Offset(cx, size.height * 0.9);
      final h = size.height * 0.85;
      final bend = bends[i];
      final tipX = base.dx + bend * h * 0.55;
      final tipY = base.dy - h + bend * h * 0.12;
      final path = Path()
        ..moveTo(base.dx - h * 0.18, base.dy)
        ..lineTo(tipX, tipY)
        ..lineTo(base.dx + h * 0.18, base.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ConeSequenceStripPainter old) =>
      old.highlighted != highlighted;
}
