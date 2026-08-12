import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/common/photo_bottom_sheet.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/providers/image_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/input_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class AddScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  final int currentIndex;
  const AddScreen({super.key, this.isEdit = false, this.currentIndex = 0});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _hearthError = false;

  late final TextEditingController _hearthCtrl;
  late final TextEditingController _deformationTempCtrl;
  late final TextEditingController _filamentCtrl;
  late final TextEditingController _filterGlassCtrl;
  late final TextEditingController _wedgwoodCtrl;
  late final TextEditingController _eraCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagsCtrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final p = ref.read(inputProvider);
    _hearthCtrl = TextEditingController(text: p.smeltingHearthComplex);
    _deformationTempCtrl =
        TextEditingController(text: p.deformationTemperatureTarget);
    _filamentCtrl = TextEditingController(text: p.filamentLampResistance);
    _filterGlassCtrl = TextEditingController(text: p.filterGlassDensity);
    _wedgwoodCtrl =
        TextEditingController(text: p.wedgwoodExpansionCoefficient);
    _eraCtrl = TextEditingController(text: p.era);
    _notesCtrl = TextEditingController(text: p.notes);
    _tagsCtrl = TextEditingController(text: p.tags.join(', '));
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in [
      _hearthCtrl,
      _deformationTempCtrl,
      _filamentCtrl,
      _filterGlassCtrl,
      _wedgwoodCtrl,
      _eraCtrl,
      _notesCtrl,
      _tagsCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeInOut,
      );

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _syncToProvider() {
    final p = ref.read(inputProvider);
    p.smeltingHearthComplex = _hearthCtrl.text.trim();
    p.deformationTemperatureTarget = _deformationTempCtrl.text.trim();
    p.filamentLampResistance = _filamentCtrl.text.trim();
    p.filterGlassDensity = _filterGlassCtrl.text.trim();
    p.wedgwoodExpansionCoefficient = _wedgwoodCtrl.text.trim();
    p.era = _eraCtrl.text.trim();
    p.notes = _notesCtrl.text.trim();
    p.tags = _parseTags(_tagsCtrl.text);
  }

  void _save() async {
    _syncToProvider();

    if (_hearthCtrl.text.trim().isEmpty) {
      setState(() => _hearthError = true);
      _goTo(0);
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _hearthError = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SavingDialog(),
    );
    await Future.delayed(const Duration(milliseconds: 650));
    if (widget.isEdit) {
      ref.read(projectProvider).editEntry(ref, widget.currentIndex);
    } else {
      ref.read(projectProvider).addEntry(ref);
    }
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
    ref.read(inputProvider).clearAll();
    ref.read(imageProvider).clearImage();
  }

  void _clearHearthError() {
    if (_hearthError) setState(() => _hearthError = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kilnHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _pageIdentity(),
                    _pageSpecs(),
                    _pageProvenance(),
                  ],
                ),
              ),
            ],
          ),
          if (_hearthError) _hearthErrorBanner(),
          Positioned(
            left: 18.w,
            right: 18.w,
            bottom: MediaQuery.of(context).padding.bottom + 14.h,
            child: _floatingNavPill(),
          ),
        ],
      ),
    );
  }

  Widget _kilnHeader() {
    const steps = ['Identity', 'Optical Specs', 'Provenance'];
    final stepTitle = steps[_currentPage];

    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border(
          bottom: BorderSide(color: kOutline.withValues(alpha: 0.85)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18.w,
          MediaQuery.of(context).padding.top + 10.h,
          18.w,
          16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _headerCloseButton(),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kOrangeSurface,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kAccent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    widget.isEdit ? 'EDIT RECORD' : 'NEW RECORD',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              'Step ${_currentPage + 1} · $stepTitle',
              style: GoogleFonts.inter(
                color: kSecondaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 14.h),
            _stepRail(),
          ],
        ),
      ),
    );
  }

  Widget _headerCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: kBackground,
          shape: BoxShape.circle,
          border: Border.all(color: kOutline),
        ),
        child: Icon(Icons.close_rounded, color: kPrimaryText, size: 20.sp),
      ),
    );
  }

  Widget _stepRail() {
    const labels = ['Identity', 'Specs', 'Provenance'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = constraints.maxWidth / labels.length;
        return SizedBox(
          height: 54.h,
          child: Stack(
            children: [
              Positioned(
                top: 11.h,
                left: segment * 0.5,
                right: segment * 0.5,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: kOutline,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                  ),
                ),
              ),
              Positioned(
                top: 11.h,
                left: segment * 0.5,
                width: segment * _currentPage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeInOut,
                  height: 2,
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final active = i == _currentPage;
                  final done = i < _currentPage;
                  return Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 230),
                          curve: Curves.easeInOut,
                          width: active ? 24.w : 20.w,
                          height: active ? 24.w : 20.w,
                          decoration: BoxDecoration(
                            color: done
                                ? kSecondaryAccent
                                : active
                                    ? kAccent
                                    : kBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active || done
                                  ? Colors.transparent
                                  : kOutline,
                              width: 1.5,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: kAccent.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: done
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 12.sp,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: GoogleFonts.ibmPlexMono(
                                      color: active
                                          ? Colors.white
                                          : kSecondaryText,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          labels[i].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexMono(
                            color: active ? kAccent : kSecondaryText,
                            fontSize: 7.sp,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hearthErrorBanner() {
    return Positioned(
      left: 18.w,
      right: 18.w,
      bottom: MediaQuery.of(context).padding.bottom + 88.h,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: kOrangeSurface,
            borderRadius: BorderRadius.circular(kRadiusStandard),
            border: Border.all(color: kError.withValues(alpha: 0.55)),
            boxShadow: const [kShadowSubtle],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: kError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  color: kError,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hearth complex required',
                      style: GoogleFonts.playfairDisplay(
                        color: kPrimaryText,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Name the smelting hearth or glassworks complex before saving this kiln record.',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _hearthError = false),
                child: Icon(
                  Icons.close_rounded,
                  color: kSecondaryText,
                  size: 18.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingNavPill() {
    final isLast = _currentPage >= 2;
    final primaryLabel = isLast
        ? (widget.isEdit ? 'Update record' : 'Save to archive')
        : 'Next';

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: kPanelBg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowFloat],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: _pillButton(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                primary: false,
                onTap: () => _goTo(_currentPage - 1),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            flex: _currentPage > 0 ? 2 : 1,
            child: _pillButton(
              label: primaryLabel,
              icon: isLast
                  ? Icons.inventory_2_outlined
                  : Icons.arrow_forward_rounded,
              primary: true,
              onTap: () {
                if (_currentPage < 2) {
                  _goTo(_currentPage + 1);
                } else {
                  _save();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        height: 48.h,
        decoration: BoxDecoration(
          color: primary ? kAccent : kBackground,
          borderRadius: BorderRadius.circular(kRadiusPill),
          border: Border.all(color: primary ? kAccent : kOutline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!primary) ...[
              Icon(icon, color: kPrimaryText, size: 16.sp),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexMono(
                  color: primary ? Colors.white : kPrimaryText,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (primary) ...[
              SizedBox(width: 6.w),
              Icon(icon, color: Colors.white, size: 16.sp),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pageIdentity() {
    final p = ref.watch(inputProvider);
    return _page('01', 'Identity', [
      _photoSection(),
      SizedBox(height: 24.h),
      _matrixPreview(),
      _enumGroup<PyrometricSystem>(
        'PYROMETRIC SYSTEM',
        PyrometricSystem.values,
        p.pyrometricSystem,
        (v) => ref.read(inputProvider).pyrometricSystem = v,
        (v) => v.label,
        accentBuilder: getSystemColor,
      ),
      _enumGroup<ConeMineralFormulation>(
        'CONE MINERAL FORMULATION',
        ConeMineralFormulation.values,
        p.coneMineralFormulation,
        (v) => ref.read(inputProvider).coneMineralFormulation = v,
        (v) => v.label,
      ),
      _field(
        'SMELTING HEARTH COMPLEX',
        _hearthCtrl,
        'Sèvres National, Meissen Royal, Stourbridge Crown',
        (v) {
          _clearHearthError();
          ref.read(inputProvider).smeltingHearthComplex = v;
        },
        required: true,
        hasError: _hearthError,
        errorText: 'Enter the originating hearth or glassworks complex.',
      ),
      _field(
        'DEFORMATION TEMPERATURE TARGET',
        _deformationTempCtrl,
        'Cone 04 / 1060°C',
        (v) => ref.read(inputProvider).deformationTemperatureTarget = v,
        mono: true,
      ),
      _enumGroup<DeformationModelStatus>(
        'DEFORMATION STATUS',
        DeformationModelStatus.values,
        p.deformationStatus,
        (v) => ref.read(inputProvider).deformationStatus = v,
        (v) => v.label,
        accentBuilder: getDeformationColor,
      ),
    ]);
  }

  Widget _pageSpecs() {
    final p = ref.watch(inputProvider);
    return _page('02', 'Optical Specs', [
      _field(
        'FILAMENT LAMP RESISTANCE',
        _filamentCtrl,
        '12.4 Ω',
        (v) => ref.read(inputProvider).filamentLampResistance = v,
        mono: true,
      ),
      _field(
        'FILTER GLASS DENSITY',
        _filterGlassCtrl,
        '1.8 ND',
        (v) => ref.read(inputProvider).filterGlassDensity = v,
        mono: true,
      ),
      _field(
        'WEDGWOOD EXPANSION COEFFICIENT',
        _wedgwoodCtrl,
        '0.012',
        (v) => ref.read(inputProvider).wedgwoodExpansionCoefficient = v,
        mono: true,
      ),
      _enumGroup<SlagColorIndex>(
        'SLAG COLOR INDEX',
        SlagColorIndex.values,
        p.slagColorIndex,
        (v) => ref.read(inputProvider).slagColorIndex = v,
        (v) => v.label,
      ),
      _enumGroup<SightTubeThreadPitch>(
        'SIGHT TUBE THREAD PITCH',
        SightTubeThreadPitch.values,
        p.sightTubeThreadPitch,
        (v) => ref.read(inputProvider).sightTubeThreadPitch = v,
        (v) => v.label,
      ),
    ]);
  }

  Widget _pageProvenance() {
    return _page('03', 'Provenance', [
      _field(
        'ERA',
        _eraCtrl,
        '1880-1920',
        (v) => ref.read(inputProvider).era = v,
        inputFormatters: const [_EraInputFormatter()],
      ),
      _field(
        'NOTES',
        _notesCtrl,
        'Cone bend angle, cylinder shrinkage, optical matching notes...',
        (v) => ref.read(inputProvider).notes = v,
        maxLines: 5,
      ),
      _field(
        'TAGS',
        _tagsCtrl,
        'Optional — comma separated, e.g. seger, berlin, porcelain',
        (v) => ref.read(inputProvider).tags = _parseTags(v),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          'Tags are optional archive labels for filtering kiln records later.',
          style: GoogleFonts.inter(
            color: kSecondaryText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
        ),
      ),
    ]);
  }

  Widget _page(String num, String title, List<Widget> children) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 96.h;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                num,
                style: GoogleFonts.ibmPlexMono(
                  color: kAccent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12.w),
              Container(width: 24.w, height: 1, color: kOutline),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: kPrimaryText,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          ...children,
        ],
      ),
    );
  }

  Widget _photoSection() {
    final imagePath = ref
        .watch(imageProvider)
        .getImagePath(ref.watch(imageProvider).resultImage);
    return GestureDetector(
      onTap: () => photoBottomSheet(context, ref.read(imageProvider), 0, ref),
      child: Container(
        width: double.infinity,
        height: 166.h,
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(color: kOutline),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath != null && File(imagePath).existsSync()
            ? Image.file(File(imagePath), fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    color: kAccent.withValues(alpha: 0.45),
                    size: 32.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'TAP TO PHOTOGRAPH INSTRUMENT',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _matrixPreview() {
    final p = ref.watch(inputProvider);
    final preview = widget.isEdit && p.thermalConeMatrixId.isNotEmpty
        ? p.thermalConeMatrixId
        : 'GFH-${systemCode(p.pyrometricSystem)}-###-AUTO';
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kSelectedTint,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, color: kAccent, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? 'THERMAL CONE MATRIX ID'
                      : 'AUTO-GENERATED MATRIX ID',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  preview,
                  style: GoogleFonts.ibmPlexMono(
                    color: kPrimaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isEdit)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: kBlueSurface,
                borderRadius: BorderRadius.circular(kRadiusPill),
                border: Border.all(
                  color: kSecondaryAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'READ-ONLY',
                style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryAccent,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
    bool hasError = false,
    String? errorText,
    bool mono = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (required)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: kOrangeSurface,
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      border: Border.all(
                        color: hasError
                            ? kError.withValues(alpha: 0.6)
                            : kAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'REQUIRED',
                      style: GoogleFonts.ibmPlexMono(
                        color: hasError ? kError : kAccent,
                        fontSize: 7.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: mono
                ? GoogleFonts.ibmPlexMono(
                    color: kPrimaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  )
                : GoogleFonts.inter(
                    color: kPrimaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: kPanelBg,
              labelStyle: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              hintStyle: GoogleFonts.inter(
                color: kSecondaryText.withValues(alpha: 0.7),
                fontSize: 13.sp,
                fontWeight: FontWeight.w300,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                borderSide: BorderSide(
                  color: hasError ? kError : kOutline,
                  width: hasError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                borderSide: BorderSide(
                  color: hasError ? kError : kAccent,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                borderSide: const BorderSide(color: kError, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                borderSide: const BorderSide(color: kError, width: 1.5),
              ),
            ),
          ),
          if (hasError && errorText != null) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: kError, size: 14.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.inter(
                      color: kError,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _enumGroup<T>(
    String label,
    List<T> values,
    T current,
    ValueChanged<T> onSelected,
    String Function(T) labelBuilder, {
    Color Function(T)? accentBuilder,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: values.map((value) {
              final selected = value == current;
              final accent = accentBuilder?.call(value) ?? kAccent;
              return GestureDetector(
                onTap: () => onSelected(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent : kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    border: Border.all(
                      color: selected ? accent : kOutline,
                    ),
                  ),
                  child: Text(
                    labelBuilder(value),
                    style: GoogleFonts.inter(
                      color: selected ? Colors.white : kPrimaryText,
                      fontSize: 12.sp,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EraInputFormatter extends TextInputFormatter {
  const _EraInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var digitCount = 0;
    var hyphenCount = 0;

    for (final char in newValue.text.split('')) {
      if (char == '-' && hyphenCount < 1 && digitCount > 0) {
        buffer.write('-');
        hyphenCount++;
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        if (hyphenCount == 0 && digitCount < 4) {
          buffer.write(char);
          digitCount++;
        } else if (hyphenCount == 1) {
          final afterHyphen = buffer.toString().split('-').last.length;
          if (afterHyphen < 4) {
            buffer.write(char);
          }
        }
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _SavingDialog extends StatelessWidget {
  const _SavingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kPanelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusStandard),
        side: const BorderSide(color: kOutline),
      ),
      child: Padding(
        padding: EdgeInsets.all(34.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42.w,
              height: 42.w,
              child: const CircularProgressIndicator(
                color: kAccent,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'LOGGING INSTRUMENT',
              style: GoogleFonts.ibmPlexMono(
                color: kPrimaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Recording the thermal instrument to the kiln archive.',
              textAlign: TextAlign.center,
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
    );
  }
}
