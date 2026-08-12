import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/screens/home_screen.dart';
import 'package:gauging_the_furnace_hearth/screens/settings_screen.dart';
import 'package:gauging_the_furnace_hearth/screens/showcase_screen.dart';
import 'package:gauging_the_furnace_hearth/screens/stats_screen.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final int index;
  const MainNavigation({super.key, this.index = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  late int _currentIndex;

  // Kept alive for tab state, but tickers only run on the visible tab.
  static const _screens = <Widget>[
    HomeScreen(key: ValueKey('tab_archive')),
    ShowcaseScreen(key: ValueKey('tab_deform')),
    StatsScreen(key: ValueKey('tab_logbook')),
    SettingsScreen(key: ValueKey('tab_compare')),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index.clamp(0, _screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < _screens.length; i++)
                TickerMode(
                  enabled: safeIndex == i,
                  child: _screens[i],
                ),
            ],
          ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom:
                MediaQuery.of(context).padding.bottom + kBottomNavBarMargin.h,
            child: _buildNav(safeIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildNav(int selectedIndex) {
    return Container(
      height: kBottomNavBarHeight.h,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowFloat],
      ),
      child: Row(
        children: [
          _navItem(0, selectedIndex, Icons.inventory_2_outlined, 'Archive'),
          _navItem(1, selectedIndex, Icons.change_history_rounded, 'Deform'),
          _navItem(2, selectedIndex, Icons.menu_book_rounded, 'Logbook'),
          _navItem(3, selectedIndex, Icons.compare_arrows_rounded, 'Compare'),
        ],
      ),
    );
  }

  Widget _navItem(
    int index,
    int selectedIndex,
    IconData icon,
    String label,
  ) {
    final selected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: selected ? kAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(kRadiusPill),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : kPrimaryText.withValues(alpha: 0.38),
                  size: 20.sp,
                ),
                SizedBox(height: 3.h),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    color: selected
                        ? Colors.white
                        : kPrimaryText.withValues(alpha: 0.38),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
