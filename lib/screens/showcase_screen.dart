import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';
import 'package:gauging_the_furnace_hearth/providers/project_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

/// Seger Cone Thermal Slump Simulator — Interactive Utility 4.3a
/// Ceramic deformation under heat-work: ramp → soak → viscous tip bend.
class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;

  // Kiln schedule inputs
  double _rampRate = 150; // °C/hr
  double _peakTemp = 1220; // °C
  double _soakMinutes = 20;
  KilnAtmosphere _atmosphere = KilnAtmosphere.oxidising;

  // Animation / scrub state
  double _simTimeHr = 0; // hours along firing schedule
  double _displayTemp = 20; // current modelled kiln temperature
  double _heatWork = 0; // accumulated heat-work index
  bool _playing = true;
  bool _scrubbing = false;
  bool _seededFromArchive = false;

  Duration _lastElapsed = Duration.zero;

  // Nominal Seger SK6-ish deformation rating (adjusted by rate & atm)
  static const double _ratedTDef = 1220;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedPeakFromArchive());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _seedPeakFromArchive() {
    if (_seededFromArchive || !mounted) return;
    final entries = ref.read(projectProvider).entries;
    if (entries.isEmpty) return;
    final raw = entries.first.deformationTemperatureTarget;
    final parsed = double.tryParse(
      raw.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (parsed != null && parsed >= 800 && parsed <= 1600) {
      setState(() {
        _peakTemp = parsed;
        _seededFromArchive = true;
      });
    } else {
      _seededFromArchive = true;
    }
  }

  // ── Physics helpers ──────────────────────────────────────────────────────

  double get _atmCorrection {
    switch (_atmosphere) {
      case KilnAtmosphere.oxidising:
        return 0;
      case KilnAtmosphere.reducing:
        return -15;
      case KilnAtmosphere.neutral:
        return -5;
    }
  }

  /// Heating-rate sensitivity: faster ramp → higher apparent T_def (+°C per 100 °C/hr above 100).
  double get _rateSensitivity => ((_rampRate - 100) / 100) * 8;

  double get _tDef =>
      (_ratedTDef + _rateSensitivity + _atmCorrection).clamp(900, 1550);

  double get _scheduleHours {
    final heatUp = (_peakTemp - 20) / _rampRate;
    return heatUp + (_soakMinutes / 60);
  }

  double _tempAtTime(double tHr) {
    final heatUp = (_peakTemp - 20) / _rampRate;
    if (tHr <= 0) return 20;
    if (tHr < heatUp) return 20 + tHr * _rampRate;
    return _peakTemp;
  }

  /// Bend angle θ: 0° upright → 90° full tip-touch.
  double get _bendAngle {
    final overshoot = _displayTemp - _tDef;
    if (overshoot < -80) return 0;
    if (overshoot < 0) {
      // approach zone: soft onset to ~45°
      final u = (overshoot + 80) / 80;
      return 45 * u * u;
    }
    // past rated: accelerate toward full slump
    final soakBoost = (_simTimeHr > (_peakTemp - 20) / _rampRate)
        ? (_simTimeHr - (_peakTemp - 20) / _rampRate) * 40
        : 0.0;
    final raw = 45 + overshoot * 1.1 + soakBoost + _heatWork * 0.08;
    return raw.clamp(0, 90);
  }

  /// Wedgwood ΔL shrinkage estimate (mm) from peak + soak.
  double get _deltaL {
    final base = ((_peakTemp - 600) / 200).clamp(0, 8);
    final soak = _soakMinutes * 0.035;
    final atm = _atmosphere == KilnAtmosphere.reducing ? 0.4 : 0;
    return (base + soak + atm).clamp(0, 12);
  }

  /// log₁₀(η) viscosity model — critical slump threshold ~ logη = 6.5.
  double _logViscosity(double tC) {
    // Vogel-Fulcher-ish ceramic body: η drops steeply near deformation.
    final tK = tC + 273.15;
    final t0 = 700 + 273.15;
    final a = 4.2e3;
    final logEta = 2.8 + a / (tK - t0);
    return logEta.clamp(3.5, 14);
  }

  static const double _criticalLogEta = 6.5;

  /// PET (pyrometric equivalent temperature) as nearest Seger SK label.
  String get _petLabel {
    final t = _tDef;
    // Rough Seger map around mid-fire
    if (t < 1100) return 'SK1a';
    if (t < 1160) return 'SK4';
    if (t < 1200) return 'SK5';
    if (t < 1240) return 'SK6';
    if (t < 1280) return 'SK7';
    if (t < 1320) return 'SK8';
    if (t < 1380) return 'SK10';
    if (t < 1460) return 'SK12';
    if (t < 1550) return 'SK14';
    return 'SK16';
  }

  /// Disappearing-filament lamp current estimate (A) vs temperature.
  double _filamentCurrent(double tC) {
    // Empirical-ish: I ∝ T^0.65 after blackbody calibration curve.
    final norm = ((tC - 700) / (1600 - 700)).clamp(0.0, 1.0);
    return 0.35 + 0.95 * math.pow(norm, 0.65);
  }

  // ── Ticker ───────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    // When paused and not scrubbing, skip rebuilds.
    if (!_playing && !_scrubbing) return;

    if (_playing && !_scrubbing) {
      // Compress schedule: full firing in ~18 simulated seconds of wall time.
      final speed = _scheduleHours / 18.0;
      _simTimeHr = (_simTimeHr + dt * speed);
      if (_simTimeHr >= _scheduleHours) {
        _simTimeHr = _scheduleHours;
        // Soft loop after a brief hold at peak
        _simTimeHr =
            math.min(_simTimeHr + dt * speed * 0.15, _scheduleHours + 0.4);
        if (_simTimeHr >= _scheduleHours + 0.35) {
          _simTimeHr = 0;
          _heatWork = 0;
        }
      }
    }

    final targetTemp = _tempAtTime(_simTimeHr.clamp(0, _scheduleHours));
    // Smooth thermal lag for kinetic feel
    _displayTemp += (targetTemp - _displayTemp) * (1 - math.exp(-dt * 4.5));

    // Heat-work accumulates when near/above deformation
    if (_displayTemp > _tDef - 60) {
      _heatWork += dt * ((_displayTemp - (_tDef - 60)) / 40).clamp(0, 3);
    } else {
      _heatWork = math.max(0, _heatWork - dt * 0.4);
    }

    if (mounted) setState(() {});
  }

  void _scrubFromDx(double dx, double width) {
    final frac = (dx / width).clamp(0.0, 1.0);
    _simTimeHr = frac * _scheduleHours;
    _displayTemp = _tempAtTime(_simTimeHr);
    _heatWork = math.max(0, (_displayTemp - (_tDef - 60)) * 0.15);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Re-try archive seed once entries finish loading.
    final project = ref.watch(projectProvider);
    if (!_seededFromArchive && !project.isLoading && project.entries.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedPeakFromArchive());
    }

    final bottomPad = bottomNavOverlayHeight(context) + 20.h;
    final progress = (_scheduleHours <= 0)
        ? 0.0
        : (_simTimeHr / _scheduleHours).clamp(0.0, 1.0);
    final thermalT =
        ((_displayTemp - 700) / (_peakTemp.clamp(800, 1600) - 700)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _simPanel(
                      progress: progress,
                      thermalT: thermalT,
                    ),
                    SizedBox(height: 16.h),
                    _controlsCard(),
                    SizedBox(height: 16.h),
                    _outputsCard(),
                    SizedBox(height: 16.h),
                    _viscosityCard(),
                    SizedBox(height: 16.h),
                    _pyrometerCard(),
                    SizedBox(height: bottomPad),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEFORMATION MODEL',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: kAccent,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Seger Cone Thermal\nSlump Simulator',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: kPrimaryText,
              height: 1.05,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Heat-work accumulation and viscous tip bend under kiln ramp, soak, and atmosphere.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w300,
              color: kSecondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _simPanel({required double progress, required double thermalT}) {
    return Container(
      decoration: BoxDecoration(
        color: kSimPanel,
        borderRadius: BorderRadius.circular(kRadiusSubtle.r),
        border: Border.all(color: kOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                Text(
                  'CONE SEQUENCE',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: kSecondaryText,
                  ),
                ),
                const Spacer(),
                _monoChip(
                  '${_displayTemp.toStringAsFixed(0)}°C',
                  color: thermalColorForProgress(thermalT),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => setState(() => _playing = !_playing),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      border: Border.all(color: kOutline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 14.sp,
                          color: kAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _playing ? 'RUN' : 'HOLD',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.55,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragStart: (_) {
                    setState(() {
                      _scrubbing = true;
                      _playing = false;
                    });
                  },
                  onHorizontalDragUpdate: (d) {
                    setState(() => _scrubFromDx(d.localPosition.dx, constraints.maxWidth));
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _scrubbing = false);
                  },
                  onTapDown: (d) {
                    setState(() {
                      _scrubbing = true;
                      _playing = false;
                      _scrubFromDx(d.localPosition.dx, constraints.maxWidth);
                    });
                  },
                  onTapUp: (_) => setState(() => _scrubbing = false),
                  child: CustomPaint(
                    painter: _ConeSlumpPainter(
                      bendAngleDeg: _bendAngle,
                      displayTemp: _displayTemp,
                      tDef: _tDef,
                      peakTemp: _peakTemp,
                      progress: progress,
                      heatWork: _heatWork,
                      scrubbing: _scrubbing,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 12.h),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: kOutline,
                    color: kAccent,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      'drag to scrub timeline',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w300,
                        color: kSecondaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'θ ${_bendAngle.toStringAsFixed(0)}°',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: kAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlsCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle.r),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kiln schedule',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: kPrimaryText,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Ramp, peak, soak, and atmosphere set the heat-work path.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              color: kSecondaryText,
            ),
          ),
          SizedBox(height: 16.h),
          _sliderRow(
            label: 'Ramp rate',
            valueLabel: '${_rampRate.toStringAsFixed(0)} °C/hr',
            value: _rampRate,
            min: 50,
            max: 300,
            onChanged: (v) => setState(() {
              _rampRate = v;
              _simTimeHr = _simTimeHr.clamp(0, _scheduleHours);
            }),
          ),
          SizedBox(height: 10.h),
          _sliderRow(
            label: 'Peak temperature',
            valueLabel: '${_peakTemp.toStringAsFixed(0)} °C',
            value: _peakTemp,
            min: 800,
            max: 1600,
            onChanged: (v) => setState(() {
              _peakTemp = v;
              _simTimeHr = _simTimeHr.clamp(0, _scheduleHours);
            }),
          ),
          SizedBox(height: 10.h),
          _sliderRow(
            label: 'Soak at peak',
            valueLabel: '${_soakMinutes.toStringAsFixed(0)} min',
            value: _soakMinutes,
            min: 0,
            max: 120,
            onChanged: (v) => setState(() {
              _soakMinutes = v;
              _simTimeHr = _simTimeHr.clamp(0, _scheduleHours);
            }),
          ),
          SizedBox(height: 14.h),
          Text(
            'Kiln atmosphere',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: kSecondaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: KilnAtmosphere.values.map((atm) {
              final selected = atm == _atmosphere;
              return GestureDetector(
                onTap: () => setState(() => _atmosphere = atm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: selected ? kSelectedTint : kBackground,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(
                      color: selected ? kAccent : kOutline,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    atm.label,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? kAccent : kSecondaryText,
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

  Widget _outputsCard() {
    final atmSign = _atmCorrection >= 0 ? '+' : '';
    final rateSign = _rateSensitivity >= 0 ? '+' : '';
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle.r),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deformation outputs',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: kPrimaryText,
            ),
          ),
          SizedBox(height: 14.h),
          _metric('T_def', '${_tDef.toStringAsFixed(0)} °C'),
          _metric('θ bend', '${_bendAngle.toStringAsFixed(1)} °'),
          _metric('ΔL Wedgwood', '${_deltaL.toStringAsFixed(2)} mm'),
          _metric(
            'Rate sensitivity',
            '$rateSign${_rateSensitivity.toStringAsFixed(1)} °C / 100 °C·hr⁻¹',
          ),
          _metric(
            'Atmosphere Δatm',
            '$atmSign${_atmCorrection.toStringAsFixed(0)} °C · ${_atmosphere.label}',
          ),
          _metric('PET equivalent', _petLabel),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: kOrangeSurface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: kOutline),
            ),
            child: Text(
              _statusLine(),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: kAccent,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLine() {
    if (_bendAngle < 8) return 'DFORM: UPRIGHT · heat-work accumulating';
    if (_bendAngle < 45) return 'DFORM: PARTIAL SLUMP · tip softening';
    if (_bendAngle < 85) return 'DFORM: ADVANCED SLUMP · near tip-touch';
    return 'DFORM: FULL SLUMP · T ≥ T_def';
  }

  Widget _viscosityCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle.r),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log-viscosity vs temperature',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: kPrimaryText,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Critical gravitational slump where log₁₀(η) crosses ${_criticalLogEta.toStringAsFixed(1)}.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              color: kSecondaryText,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 160.h,
            width: double.infinity,
            child: CustomPaint(
              painter: _ViscosityCurvePainter(
                logViscosityAt: _logViscosity,
                criticalLogEta: _criticalLogEta,
                currentTemp: _displayTemp,
                tDef: _tDef,
                tMin: 800,
                tMax: 1600,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _legendDot(kAccent, 'η(T)'),
              SizedBox(width: 14.w),
              _legendDot(kSecondaryAccent, 'calibration'),
              SizedBox(width: 14.w),
              Text(
                'log η ${_logViscosity(_displayTemp).toStringAsFixed(2)}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pyrometerCard() {
    final iFil = _filamentCurrent(_displayTemp);
    final iAtDef = _filamentCurrent(_tDef);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle.r),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: kSecondaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Optical pyrometer matching',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Disappearing-filament cross-check against cone deformation state.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              color: kSecondaryText,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: kBlueSurface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: kOutline),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 110.h,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _PyrometerFilamentPainter(
                      currentTemp: _displayTemp,
                      tDef: _tDef,
                      filamentCurrentAt: _filamentCurrent,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _pyroStat(
                        'I_fil',
                        '${iFil.toStringAsFixed(3)} A',
                      ),
                    ),
                    Expanded(
                      child: _pyroStat(
                        'I @ T_def',
                        '${iAtDef.toStringAsFixed(3)} A',
                      ),
                    ),
                    Expanded(
                      child: _pyroStat(
                        'Match',
                        (_displayTemp - _tDef).abs() < 25 ? 'VALID' : 'DRIFT',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Small UI atoms ───────────────────────────────────────────────────────

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: kSecondaryText,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: kPrimaryText,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: kAccent,
            inactiveTrackColor: kOutline,
            thumbColor: kAccent,
            overlayColor: kAccent.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _metric(String key, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              key,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: kSecondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: kPrimaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monoChip(String text, {required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: kSecondaryText,
          ),
        ),
      ],
    );
  }

  Widget _pyroStat(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: kSecondaryAccent,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          v,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: kPrimaryText,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painters
// ═══════════════════════════════════════════════════════════════════════════

class _ConeSlumpPainter extends CustomPainter {
  final double bendAngleDeg;
  final double displayTemp;
  final double tDef;
  final double peakTemp;
  final double progress;
  final double heatWork;
  final bool scrubbing;

  _ConeSlumpPainter({
    required this.bendAngleDeg,
    required this.displayTemp,
    required this.tDef,
    required this.peakTemp,
    required this.progress,
    required this.heatWork,
    required this.scrubbing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pad = size.width * 0.04;
    final groundY = size.height * 0.88;

    // Soft floor rule
    final floorPaint = Paint()
      ..color = kOutline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, groundY), Offset(size.width - pad, groundY), floorPaint);

    // Sequence of silhouette cones at temperature intervals around T_def
    final temps = <double>[];
    for (var t = tDef - 100; t <= tDef + 80; t += 45) {
      temps.add(t);
    }
    if (temps.isEmpty) temps.add(tDef);

    final slotW = (size.width - pad * 2) / temps.length;

    for (var i = 0; i < temps.length; i++) {
      final t = temps[i];
      final thermalProg =
          ((t - (tDef - 120)) / 220).clamp(0.0, 1.0);
      final color = thermalColorForProgress(thermalProg);
      final isCurrent = (displayTemp - t).abs() < 28;
      final localBend = _bendForTemp(t);
      final cx = pad + slotW * (i + 0.5);
      final coneH = size.height * (isCurrent ? 0.58 : 0.42);
      final opacity = isCurrent ? 1.0 : 0.38;

      canvas.save();
      _drawCone(
        canvas,
        Offset(cx, groundY),
        coneH,
        localBend,
        color.withValues(alpha: opacity),
        highlight: isCurrent,
      );
      canvas.restore();

      // Temperature label under each silhouette
      final tp = TextPainter(
        text: TextSpan(
          text: '${t.toStringAsFixed(0)}°',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: isCurrent ? 10 : 8,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? kAccent : kSecondaryText.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, groundY + 6));
    }

    // Large animated hero cone (current state) overlaid left-of-center
    final heroCx = size.width * 0.22;
    final heroH = size.height * 0.72;
    final heroColor = thermalColorForProgress(
      ((displayTemp - 700) / (peakTemp - 700 + 1e-6)).clamp(0.0, 1.0),
    );
    _drawCone(
      canvas,
      Offset(heroCx, groundY),
      heroH,
      bendAngleDeg,
      heroColor,
      highlight: true,
      strokeWidth: 2.2,
    );

    // Heat shimmer near tip when hot
    if (displayTemp > tDef - 40) {
      final tip = _tipPoint(Offset(heroCx, groundY), heroH, bendAngleDeg);
      final shimmer = Paint()
        ..color = heroColor.withValues(alpha: 0.18 + 0.08 * math.sin(heatWork))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(tip, 18 + heatWork.clamp(0, 8), shimmer);
    }

    // Playhead marker along timeline
    final playX = pad + (size.width - pad * 2) * progress.clamp(0.0, 1.0);
    final playPaint = Paint()
      ..color = scrubbing ? kSecondaryAccent : kAccent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(playX, 8), Offset(playX, groundY - 4), playPaint);
    canvas.drawCircle(Offset(playX, 8), 3.5, Paint()..color = playPaint.color);

    // Title label for current T
    final label = TextPainter(
      text: TextSpan(
        text: 'T ${displayTemp.toStringAsFixed(0)}°C  ·  T_def ${tDef.toStringAsFixed(0)}°C',
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kPrimaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.55);
    label.paint(canvas, Offset(size.width * 0.42, 14));
  }

  double _bendForTemp(double t) {
    final overshoot = t - tDef;
    if (overshoot < -80) return 0;
    if (overshoot < 0) {
      final u = (overshoot + 80) / 80;
      return 45 * u * u;
    }
    return (45 + overshoot * 1.1).clamp(0, 90);
  }

  Offset _tipPoint(Offset base, double height, double bendDeg) {
    final rad = bendDeg * math.pi / 180;
    // Tip rotates around upper third hinge
    final hinge = Offset(base.dx, base.dy - height * 0.55);
    final tipLocal = Offset(0, -height * 0.45);
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    // Bend toward +x (rightward tip fall)
    final rx = tipLocal.dx * cos + tipLocal.dy * sin;
    final ry = -tipLocal.dx * sin + tipLocal.dy * cos;
    return Offset(hinge.dx + rx, hinge.dy + ry);
  }

  void _drawCone(
    Canvas canvas,
    Offset base,
    double height,
    double bendDeg,
    Color color, {
    bool highlight = false,
    double strokeWidth = 1.6,
  }) {
    final baseW = height * 0.28;
    final hingeY = base.dy - height * 0.55;
    final hinge = Offset(base.dx, hingeY);

    final lower = Path()
      ..moveTo(base.dx - baseW / 2, base.dy)
      ..lineTo(base.dx + baseW / 2, base.dy)
      ..lineTo(hinge.dx + baseW * 0.18, hinge.dy)
      ..lineTo(hinge.dx - baseW * 0.18, hinge.dy)
      ..close();

    final rad = bendDeg * math.pi / 180;
    final tipLen = height * 0.45;
    final tipLocal = Offset(0, -tipLen);
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    final tip = Offset(
      hinge.dx + tipLocal.dx * cos + tipLocal.dy * sin,
      hinge.dy - tipLocal.dx * sin + tipLocal.dy * cos,
    );
    final leftHinge = Offset(hinge.dx - baseW * 0.18, hinge.dy);
    final rightHinge = Offset(hinge.dx + baseW * 0.18, hinge.dy);

    final upper = Path()
      ..moveTo(leftHinge.dx, leftHinge.dy)
      ..lineTo(rightHinge.dx, rightHinge.dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: highlight ? 0.22 : 0.12);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    canvas.drawPath(lower, fill);
    canvas.drawPath(upper, fill);
    canvas.drawPath(lower, stroke);
    canvas.drawPath(upper, stroke);

    if (highlight) {
      canvas.drawCircle(
        tip,
        3.2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConeSlumpPainter old) {
    return old.bendAngleDeg != bendAngleDeg ||
        old.displayTemp != displayTemp ||
        old.tDef != tDef ||
        old.peakTemp != peakTemp ||
        old.progress != progress ||
        old.heatWork != heatWork ||
        old.scrubbing != scrubbing;
  }
}

class _ViscosityCurvePainter extends CustomPainter {
  final double Function(double) logViscosityAt;
  final double criticalLogEta;
  final double currentTemp;
  final double tDef;
  final double tMin;
  final double tMax;

  _ViscosityCurvePainter({
    required this.logViscosityAt,
    required this.criticalLogEta,
    required this.currentTemp,
    required this.tDef,
    required this.tMin,
    required this.tMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 36.0;
    const padR = 12.0;
    const padT = 10.0;
    const padB = 32.0;
    final chart = Rect.fromLTRB(padL, padT, size.width - padR, size.height - padB);

    // Axes
    final axis = Paint()
      ..color = kOutline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axis,
    );
    canvas.drawLine(
      Offset(chart.left, chart.top),
      Offset(chart.left, chart.bottom),
      axis,
    );

    double xFor(double t) =>
        chart.left + (t - tMin) / (tMax - tMin) * chart.width;
    double yFor(double logEta) {
      const lo = 4.0;
      const hi = 12.0;
      final n = ((logEta - lo) / (hi - lo)).clamp(0.0, 1.0);
      return chart.bottom - n * chart.height;
    }

    // Critical threshold
    final yCrit = yFor(criticalLogEta);
    final critPaint = Paint()
      ..color = kAccent.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dash = Path();
    for (var x = chart.left; x < chart.right; x += 7) {
      dash.moveTo(x, yCrit);
      dash.lineTo(math.min(x + 4, chart.right), yCrit);
    }
    canvas.drawPath(dash, critPaint);

    // Calibration marks (Seger / Orton style)
    final calTemps = [tDef - 60, tDef, tDef + 60];
    for (final ct in calTemps) {
      if (ct < tMin || ct > tMax) continue;
      final p = Offset(xFor(ct), yFor(logViscosityAt(ct)));
      canvas.drawCircle(
        p,
        ct == tDef ? 4 : 3,
        Paint()..color = kSecondaryAccent,
      );
    }

    // Viscosity curve
    final path = Path();
    var started = false;
    for (var t = tMin; t <= tMax; t += 4) {
      final p = Offset(xFor(t), yFor(logViscosityAt(t)));
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Current temperature marker
    final cur = Offset(xFor(currentTemp.clamp(tMin, tMax)), yFor(logViscosityAt(currentTemp)));
    canvas.drawCircle(cur, 5, Paint()..color = kAccent);
    canvas.drawCircle(cur, 5, Paint()
      ..color = kPanelBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Axis labels
    void label(String s, Offset o, {Color? c}) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 8,
            color: c ?? kSecondaryText,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o);
    }

    label('log η', Offset(4, chart.top));
    label('crit', Offset(chart.left + 4, yCrit - 12), c: kAccent);

    // X-axis: min / max ticks, unit centered below so it never overlaps ticks.
    final minTp = TextPainter(
      text: TextSpan(
        text: '${tMin.toInt()}',
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8,
          color: kSecondaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final maxTp = TextPainter(
      text: TextSpan(
        text: '${tMax.toInt()}',
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8,
          color: kSecondaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final unitTp = TextPainter(
      text: const TextSpan(
        text: 'T °C',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8,
          color: kSecondaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    minTp.paint(canvas, Offset(chart.left, chart.bottom + 4));
    maxTp.paint(
      canvas,
      Offset(chart.right - maxTp.width, chart.bottom + 4),
    );
    unitTp.paint(
      canvas,
      Offset(chart.center.dx - unitTp.width / 2, chart.bottom + 14),
    );
  }

  @override
  bool shouldRepaint(covariant _ViscosityCurvePainter old) {
    return old.currentTemp != currentTemp ||
        old.tDef != tDef ||
        old.criticalLogEta != criticalLogEta;
  }
}

class _PyrometerFilamentPainter extends CustomPainter {
  final double currentTemp;
  final double tDef;
  final double Function(double) filamentCurrentAt;

  _PyrometerFilamentPainter({
    required this.currentTemp,
    required this.tDef,
    required this.filamentCurrentAt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 28.0;
    const padR = 10.0;
    const padT = 8.0;
    const padB = 18.0;
    final chart = Rect.fromLTRB(padL, padT, size.width - padR, size.height - padB);

    final axis = Paint()
      ..color = kSecondaryAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(chart.left, chart.bottom), Offset(chart.right, chart.bottom), axis);
    canvas.drawLine(Offset(chart.left, chart.top), Offset(chart.left, chart.bottom), axis);

    const tMin = 700.0;
    const tMax = 1600.0;
    const iMin = 0.3;
    const iMax = 1.4;

    double xFor(double t) =>
        chart.left + ((t - tMin) / (tMax - tMin)).clamp(0.0, 1.0) * chart.width;
    double yFor(double i) =>
        chart.bottom - ((i - iMin) / (iMax - iMin)).clamp(0.0, 1.0) * chart.height;

    final path = Path();
    var started = false;
    for (var t = tMin; t <= tMax; t += 8) {
      final p = Offset(xFor(t), yFor(filamentCurrentAt(t)));
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kSecondaryAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // T_def vertical guide
    final xDef = xFor(tDef);
    canvas.drawLine(
      Offset(xDef, chart.top),
      Offset(xDef, chart.bottom),
      Paint()
        ..color = kSecondaryAccent.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );

    final curI = filamentCurrentAt(currentTemp);
    final cur = Offset(xFor(currentTemp), yFor(curI));
    canvas.drawCircle(cur, 5.5, Paint()..color = kSecondaryAccent);
    canvas.drawCircle(
      cur,
      5.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Filament glow metaphor
    canvas.drawCircle(
      cur,
      14,
      Paint()
        ..color = kSecondaryAccent.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'I(T) filament',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8,
          color: kSecondaryAccent.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(chart.left + 6, chart.top + 2));
  }

  @override
  bool shouldRepaint(covariant _PyrometerFilamentPainter old) {
    return old.currentTemp != currentTemp || old.tDef != tDef;
  }
}
