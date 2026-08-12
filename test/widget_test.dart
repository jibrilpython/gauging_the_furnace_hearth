import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gauging_the_furnace_hearth/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots to initial or home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(child: MyApp(preferences: prefs)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Furnace'), findsWidgets);
  });
}
