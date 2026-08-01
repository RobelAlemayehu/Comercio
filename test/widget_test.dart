import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comercio/app/app.dart';
import 'package:comercio/core/storage/local_storage.dart';

void main() {
  testWidgets('App renders base foundation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const ComercioApp(),
      ),
    );

    expect(find.text('Comercio Base Foundation Ready'), findsOneWidget);
  });
}
