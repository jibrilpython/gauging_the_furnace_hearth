import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/providers/image_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

void photoBottomSheet(
  BuildContext context,
  ImageNotifier imageProv,
  int index,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 18.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusStandard),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowFloat],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4.h, color: kAccent),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: kSecondaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'INSTRUMENT CAPTURE',
                        style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Log Photograph',
                    style: GoogleFonts.playfairDisplay(
                      color: kPrimaryText,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Attach a profile image of the Seger cone deformation state, Wedgwood cylinder length, or optical pyrometer eyepiece assembly.',
                    style: GoogleFonts.inter(
                      color: kSecondaryText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: _captureTile(
                          ctx,
                          imageProv,
                          icon: Icons.camera_alt_rounded,
                          title: 'Capture',
                          subtitle: 'Live lens',
                          source: ImageSource.camera,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _captureTile(
                          ctx,
                          imageProv,
                          icon: Icons.photo_library_rounded,
                          title: 'Archive',
                          subtitle: 'From gallery',
                          source: ImageSource.gallery,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: kSelectedTint,
                        borderRadius: BorderRadius.circular(kRadiusPill),
                        border: Border.all(color: kOutline),
                      ),
                      child: Center(
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _captureTile(
  BuildContext ctx,
  ImageNotifier imageProv, {
  required IconData icon,
  required String title,
  required String subtitle,
  required ImageSource source,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        await imageProv.pickImage(source: source);
      },
      borderRadius: BorderRadius.circular(kRadiusSubtle),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(color: kOutline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadiusSubtle),
              ),
              child: Icon(icon, color: kAccent, size: 18.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: kPrimaryText,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
