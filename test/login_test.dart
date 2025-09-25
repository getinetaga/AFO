import 'package:afochatapplication/screens/login_screen.dart';
import 'package:afochatapplication/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Login Screen Tests', () {
    testWidgets('Login screen loads successfully', (WidgetTester tester) async {
      // Create a mock AuthService
      final authService = AuthService();
      
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify that the login screen shows
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      final authService = AuthService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const LoginScreen(),
          ),
        ),
      );

      // Try to login without entering anything
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
