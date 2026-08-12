import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gauging_the_furnace_hearth/initial_screen.dart';
import 'package:gauging_the_furnace_hearth/providers/user_provider.dart';
import 'package:gauging_the_furnace_hearth/screens/add_screen.dart';
import 'package:gauging_the_furnace_hearth/screens/info_screen.dart';
import 'package:gauging_the_furnace_hearth/screens/main_navigation.dart';
import 'package:gauging_the_furnace_hearth/screens/showcase_screen.dart';
import 'package:gauging_the_furnace_hearth/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(ProviderScope(child: MyApp(preferences: preferences)));
}

class MyApp extends ConsumerWidget {
  final SharedPreferences preferences;
  const MyApp({super.key, required this.preferences});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProv = ref.watch(userProvider);
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gauging the Furnace Hearth',
            theme: buildAppTheme(),
            home: child,
            routes: {
              '/home': (_) => const MainNavigation(),
              '/initial_screen': (_) => const InitialScreen(),
              '/showcase': (_) => const ShowcaseScreen(),
              '/add_screen': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>? ??
                    {};
                return AddScreen(
                  isEdit: args['isEdit'] as bool? ?? false,
                  currentIndex: args['index'] as int? ?? 0,
                );
              },
              '/info_screen': (_) => const InfoScreen(),
            },
          ),
        );
      },
      child: userProv.firstTimeUser
          ? const InitialScreen()
          : const MainNavigation(),
    );
  }
}
