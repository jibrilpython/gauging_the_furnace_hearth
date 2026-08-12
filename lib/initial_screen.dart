import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/providers/user_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class InitialScreen extends ConsumerWidget {
  const InitialScreen({super.key});

  Future<void> _enterArchive(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    await ref.read(userProvider).setFirstTimeUser(false);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _KilnRulePainter())),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: kPanelBg,
                                borderRadius: BorderRadius.circular(kRadiusPill),
                                border: Border.all(color: kOutline),
                              ),
                              child: Text(
                                'PYROMETRY LEDGER',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kAccent,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                            SizedBox(height: 32.h),
                            Text(
                              'Gauging the\nFurnace Hearth',
                              style: GoogleFonts.playfairDisplay(
                                color: kPrimaryText,
                                fontSize: 42.sp,
                                fontWeight: FontWeight.w700,
                                height: 0.94,
                              ),
                            ),
                            SizedBox(height: 18.h),
                            Container(width: 54.w, height: 2, color: kAccent),
                            SizedBox(height: 18.h),
                            Text(
                              'A specialized thermal archive and ceramic deformation simulator for pyrometry historians, glassworks curators, and blast furnace preservationists.',
                              style: GoogleFonts.inter(
                                color: kSecondaryText,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w300,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 48.h),
                            Center(
                              child: SizedBox(
                                width: 160.w,
                                height: 100.w,
                                child: CustomPaint(
                                  painter: _ConeSequencePainter(),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(height: 28.h),
                            SizedBox(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(kRadiusPill),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _enterArchive(context, ref),
                                    child: Ink(
                                      height: 56.h,
                                      decoration: BoxDecoration(
                                        color: kAccent,
                                        boxShadow: [
                                          BoxShadow(
                                            color: kAccent.withValues(
                                              alpha: 0.28,
                                            ),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            'ENTER THE ARCHIVE',
                                            style: GoogleFonts.ibmPlexMono(
                                              color: Colors.white,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Center(
                              child: Text(
                                'Document Seger cones, Wedgwood cylinders, and optical pyrometers.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: kSecondaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Center(
                              child: Text(
                                'The bent cone is the temperature record.',
                                style: GoogleFonts.inter(
                                  color: kSecondaryText.withValues(alpha: 0.72),
                                  fontSize: 11.sp,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KilnRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutline.withValues(alpha: 0.9)
      ..strokeWidth = 0.6;
    for (double y = 88; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 28; x < size.width; x += 72) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..color = kOutline.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KilnRulePainter oldDelegate) => false;
}

class _ConeSequencePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final positions = [0.15, 0.5, 0.85];
    final bends = [0.0, 0.45, 1.0];
    for (var i = 0; i < 3; i++) {
      final cx = size.width * positions[i];
      final bend = bends[i];
      final color = i == 2 ? kAccent : kPrimaryText.withValues(alpha: 0.35 + i * 0.15);
      _drawCone(canvas, Offset(cx, size.height * 0.72), size.height * 0.55, bend, color);
    }
  }

  void _drawCone(Canvas canvas, Offset base, double height, double bend, Color color) {
    final tipX = base.dx + bend * height * 0.55;
    final tipY = base.dy - height + bend * height * 0.15;
    final path = Path()
      ..moveTo(base.dx - height * 0.18, base.dy)
      ..lineTo(tipX, tipY)
      ..lineTo(base.dx + height * 0.18, base.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ConeSequencePainter oldDelegate) => false;
}
