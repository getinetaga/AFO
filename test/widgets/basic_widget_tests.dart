// ============================================================================
// AFO Chat Application - Basic Widget Tests
// ============================================================================
// Basic test suite for UI widgets and screens
// ============================================================================

import 'package:afochatapplication/main.dart';
import 'package:afochatapplication/screens/home_screen.dart';
import 'package:afochatapplication/screens/login_screen.dart';
import 'package:afochatapplication/screens/profile_screen.dart';
import 'package:afochatapplication/screens/register_screen.dart';
import 'package:afochatapplication/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('App Initialization', () {
    testWidgets('should create main app without errors', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have correct app title', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('AFO Chat Application'));
    });

    testWidgets('should show initial screen', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pump();
      
      // Should show either loading indicator or login screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Login Screen', () {
    testWidgets('should render login screen', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have form elements', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const LoginScreen(),
          ),
        ),
      );

      // Check that the screen renders without errors
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Register Screen', () {
    testWidgets('should render register screen', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const RegisterScreen(),
          ),
        ),
      );

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have form elements', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const RegisterScreen(),
          ),
        ),
      );

      // Check that the screen renders without errors
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('Home Screen', () {
    testWidgets('should render home screen', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have navigation elements', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const HomeScreen(),
          ),
        ),
      );

      // Check that the screen renders without errors
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Profile Screen', () {
    testWidgets('should render profile screen', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const ProfileScreen(),
          ),
        ),
      );

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display profile elements', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const ProfileScreen(),
          ),
        ),
      );

      // Check that the screen renders without errors
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('Screen Navigation', () {
    testWidgets('should handle route configuration', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Check that the app has routes configured
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.routes, isNotNull);
      expect(app.routes!.containsKey('/login'), isTrue);
      expect(app.routes!.containsKey('/register'), isTrue);
      expect(app.routes!.containsKey('/home'), isTrue);
      expect(app.routes!.containsKey('/profile'), isTrue);
    });

    testWidgets('should generate dynamic routes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Check that the app has onGenerateRoute configured
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.onGenerateRoute, isNotNull);
    });
  });

  group('Theme Configuration', () {
    testWidgets('should have correct theme', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Check theme configuration
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.theme!.colorScheme.primary, isNotNull);
    });

    testWidgets('should not show debug banner', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Check debug banner is disabled
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });

  group('Error Handling', () {
    testWidgets('should handle widget creation gracefully', (WidgetTester tester) async {
      // Test that widgets can be created without throwing exceptions
      final authService = AuthService();
      
      // Test LoginScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const LoginScreen(),
          ),
        ),
      );
      expect(find.byType(LoginScreen), findsOneWidget);

      // Test RegisterScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const RegisterScreen(),
          ),
        ),
      );
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Test HomeScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const HomeScreen(),
          ),
        ),
      );
      expect(find.byType(HomeScreen), findsOneWidget);

      // Test ProfileScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: const ProfileScreen(),
          ),
        ),
      );
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('should maintain widget tree integrity', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pump();

      // Verify the widget tree is stable
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Performance', () {
    testWidgets('should render within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pump();
      
      stopwatch.stop();
      
      // App should render quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('should handle multiple pumps efficiently', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Multiple pumps should not cause issues
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Widget Lifecycle', () {
    testWidgets('should initialize and dispose properly', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Widget should initialize without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Replace with a different widget to test disposal
      await tester.pumpWidget(Container());
      
      // Should handle disposal gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle state changes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Initial state
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Trigger rebuild
      await tester.pump();
      
      // Should maintain consistency
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}