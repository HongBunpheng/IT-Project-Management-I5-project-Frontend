import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg_intern_project/auth/screen/login_screen.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
