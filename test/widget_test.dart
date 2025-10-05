// ============================================================================
// AFO Chat Application - Widget Tests
// ============================================================================
// Comprehensive test suite for the AFO (Afaan Oromoo Chat Services) application.
// These tests ensure all components work correctly and maintain code quality.
//
// Test Coverage:
// - Service initialization and state management
// - Screen rendering and UI components
// - Form validation and user interactions
// - Navigation and routing functionality
// - Authentication flow testing
// - Call and chat functionality
//
// NOTE: Uses mock services to test without external dependencies
// ============================================================================

import 'package:afochatapplication/main.dart';
import 'package:afochatapplication/screens/call_screen.dart';
import 'package:afochatapplication/screens/chat_screen.dart';
import 'package:afochatapplication/screens/google_signin_test_screen.dart';
import 'package:afochatapplication/screens/home_screen.dart';
import 'package:afochatapplication/screens/login_screen.dart';
import 'package:afochatapplication/screens/profile_screen.dart';
import 'package:afochatapplication/screens/register_screen.dart';
import 'package:afochatapplication/services/auth_service.dart';
import 'package:afochatapplication/services/call_service.dart';
import 'package:afochatapplication/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('AFO Chat Application Tests', () {

    // =========================================================================
    // Service Tests - Core Business Logic
    // =========================================================================

    test('AuthService initializes correctly', () {
      final authService = AuthService();
      expect(authService.isAuthenticated, false);
      expect(authService.isLoading, false);
      expect(authService.user, null);
    });

    test('CallService initializes with correct defaults', () {
      final callService = CallService();
      expect(callService.status, CallStatus.idle);
      expect(callService.isMuted, false);
      expect(callService.isCameraOn, true);
      expect(callService.isSpeakerOn, false);
      callService.dispose();
    });

    test('ChatService initializes correctly', () {
      final chatService = ChatService();
      expect(chatService, isNotNull);
      chatService.dispose();
    });

    // =========================================================================
    // Widget Tests - UI Components and Screens
    // =========================================================================

    testWidgets('Main app initializes', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(MyApp(authService: authService));
      await tester.pump();

      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('Login form handles empty input validation', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Register screen renders correctly', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('Home screen renders correctly', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Profile screen renders correctly', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Google Sign-in test screen renders correctly', (WidgetTester tester) async {
      final authService = AuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: GoogleSignInTestScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSignInTestScreen), findsOneWidget);
    });

    testWidgets('Chat screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(userId: 'test_user', userName: 'Test User'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Call screen renders for video calls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CallScreen(
            remoteUserId: 'test_user',
            remoteUserName: 'Test User',
            callType: CallType.video,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CallScreen), findsOneWidget);
    });

    testWidgets('Call screen renders for voice calls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CallScreen(
            remoteUserId: 'test_user',
            remoteUserName: 'Test User',
            callType: CallType.voice,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CallScreen), findsOneWidget);
    });
  });
}
