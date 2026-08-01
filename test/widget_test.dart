import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comercio/app/app.dart';
import 'package:comercio/core/storage/local_storage.dart';

void main() {
  testWidgets('App renders LoginScreen when unauthenticated', (WidgetTester tester) async {
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

    await tester.pumpAndSettle();

    expect(find.text('Sign in to access your e-commerce dashboard'), findsOneWidget);
  });
}
