// This is a basic Flutter widget test for FreeLancer Mobile app.

import 'package:flutter_test/flutter_test.dart';

import 'package:freelancer_mobile/main.dart';

void main() {
  testWidgets('FreeLancer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FreeLancerApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that either the login screen or onboarding screen is displayed
    // (depending on authentication state)
    final welcomeBackFinder = find.text('Welcome Back!');
    final onboardingFinder = find.text('Welcome to Freelancer Mobile!');

    // Should find either the login screen or the onboarding screen
    expect(
        welcomeBackFinder.evaluate().isNotEmpty ||
            onboardingFinder.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should display either login screen or onboarding screen');
  });
}
