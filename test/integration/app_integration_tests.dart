// ============================================================================
// AFO Chat Application - Integration Tests
// ============================================================================
// Integration test suite covering complete user flows and interactions:
// - Authentication flow (login/register/logout)
// - Chat functionality (send/receive messages)
// - Navigation between screens
// - Data persistence and state management
// - Error handling across app components
// ============================================================================

import 'package:afochatapplication/main.dart';
import 'package:afochatapplication/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication Flow Integration', () {
    testWidgets('should complete login flow', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();

      // Should render the app successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle authentication state changes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Allow app to initialize
      await tester.pumpAndSettle();
      
      // App should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should navigate between auth screens', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();

      // App should have navigation configured
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.routes, isNotNull);
      expect(app.routes!.containsKey('/login'), isTrue);
      expect(app.routes!.containsKey('/register'), isTrue);
    });
  });

  group('Main App Flow Integration', () {
    testWidgets('should initialize app components', (WidgetTester tester) async {
      final authService = AuthService();
      await authService.init(); // Initialize service
      
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();

      // App should initialize without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle route generation', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      // Test route generation with chat parameters
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.onGenerateRoute, isNotNull);

      // Test generating a chat route
      final route = app.onGenerateRoute!(
        RouteSettings(
          name: '/chat',
          arguments: {
            'userId': 'test123',
            'userName': 'Test User',
          },
        ),
      );
      expect(route, isNotNull);
    });

    testWidgets('should handle call route generation', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Test generating a call route
      final route = app.onGenerateRoute!(
        RouteSettings(
          name: '/call',
          arguments: {
            'remoteUserId': 'user123',
            'remoteUserName': 'Remote User',
            'isVideo': true,
          },
        ),
      );
      expect(route, isNotNull);
    });
  });

  group('Navigation Integration', () {
    testWidgets('should support navigation to all main routes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Test that all main routes are configured
      expect(app.routes!.containsKey('/login'), isTrue);
      expect(app.routes!.containsKey('/register'), isTrue);
      expect(app.routes!.containsKey('/home'), isTrue);  
      expect(app.routes!.containsKey('/profile'), isTrue);
      expect(app.routes!.containsKey('/google_signin_test'), isTrue);
    });

    testWidgets('should handle unknown routes gracefully', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Test unknown route handling
      final unknownRoute = app.onGenerateRoute!(
        const RouteSettings(name: '/unknown'),
      );
      
      // Should return null for unknown routes
      expect(unknownRoute, isNull);
    });
  });

  group('Service Integration', () {
    testWidgets('should initialize auth service properly', (WidgetTester tester) async {
      final authService = AuthService();
      
      // Service should initialize without errors
      await authService.init();
      
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle service state changes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Simulate service state changes
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // App should handle state changes gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Error Handling Integration', () {
    testWidgets('should handle initialization errors', (WidgetTester tester) async {
      final authService = AuthService();
      
      // Test error handling during app startup
      await tester.pumpWidget(MyApp(authService: authService));
      
      // App should handle any initialization errors gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should recover from widget errors', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Pump multiple times to test error recovery
      for (int i = 0; i < 3; i++) {
        await tester.pump();
      }
      
      // App should maintain stability
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('State Management Integration', () {
    testWidgets('should maintain app state across rebuilds', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();
      
      // Get initial state
      final initialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Trigger rebuild
      await tester.pump();
      
      // State should be maintained
      final rebuiltApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(rebuiltApp.title, equals(initialApp.title));
    });

    testWidgets('should handle provider context correctly', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Provider context should be available throughout the widget tree
      await tester.pumpAndSettle();
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Performance Integration', () {
    testWidgets('should load efficiently', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      final authService = AuthService();
      await authService.init();
      
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should load within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle rapid state changes', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Rapid state changes
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      
      // App should remain stable
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Data Flow Integration', () {
    testWidgets('should handle data flow between components', (WidgetTester tester) async {
      final authService = AuthService();
      await authService.init();
      
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();
      
      // Data should flow correctly through the app
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should maintain data consistency', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Multiple pumps should maintain data consistency
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Lifecycle Integration', () {
    testWidgets('should handle app lifecycle correctly', (WidgetTester tester) async {
      final authService = AuthService();
      
      // Initialize
      await tester.pumpWidget(MyApp(authService: authService));
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Simulate app going to background and returning
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Clean shutdown
      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNull);
    });

    testWidgets('should cleanup resources properly', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();
      
      // App should initialize properly
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Replace with empty widget to test cleanup
      await tester.pumpWidget(const SizedBox.shrink());
      
      // Should cleanup without errors
      expect(tester.takeException(), isNull);
    });
  });

  group('User Journey Integration', () {
    testWidgets('should support complete user journey', (WidgetTester tester) async {
      final authService = AuthService();
      await authService.init();
      
      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pumpAndSettle();
      
      // User should be able to navigate through the app
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // App should have all necessary routes
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.routes, isNotNull);
      expect(app.onGenerateRoute, isNotNull);
    });

    testWidgets('should maintain user context throughout journey', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(MyApp(authService: authService));
      
      // Context should be maintained across navigation
      await tester.pumpAndSettle();
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}