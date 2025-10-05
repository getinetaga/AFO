// ============================================================================
// AFO Chat Application - Main Entry Point
// ============================================================================
// This is the main entry point for the AFO (Afaan Oromoo Chat Services) Application.
// It sets up the app structure, routing, and dependency injection using Provider
// pattern for state management across the entire application.
//
// Key Features:
// - Multi-Provider setup for services (AuthService, etc.)
// - Routing configuration for all screens
// - Theme configuration with professional blue color scheme
// - Error handling and initialization
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screen imports - All UI screens for the application
import 'screens/call_screen.dart';
import 'screens/chat_screen.dart';           // Chat messaging interface
import 'screens/google_signin_test_screen.dart'; // Google Sign-In testing screen
import 'screens/home_screen.dart'; // Using home_screen.dart (the main chat list)  
import 'screens/login_screen.dart';          // User authentication login
import 'screens/profile_screen.dart';        // User profile management
import 'screens/register_screen.dart';       // New user registration
// Service imports - Business logic and data management
import 'services/auth_service.dart';         // Authentication service (mock implementation)
import 'services/call_service.dart';         // Voice/video call service (mock Agora replacement)

/// Application entry point
/// Initializes Flutter widgets binding and starts the app with dependency injection
void main() async {
  // Ensure that widget binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  // Create the AuthService instance that will be shared across the app
  final authService = AuthService();
  // Initialize authentication service - loads any stored tokens
  await authService.init(); // loads tokens if any
  // Run the application with dependency injection
  runApp(MyApp(authService: authService));
}

/// Main Application Widget
/// Sets up the app structure with:
/// - Provider for state management
/// - Material Design theme configuration  
/// - Routing configuration for all screens
/// - Global error handling
class MyApp extends StatelessWidget {
  /// AuthService instance passed from main() for dependency injection
  final AuthService authService;
  
  /// Constructor requiring AuthService dependency
  const MyApp({required this.authService, super.key});

  @override
  Widget build(BuildContext context) {
    // Provider setup for dependency injection across the app
    return ChangeNotifierProvider<AuthService>.value(
      // AuthService - Manages user authentication state across the app
      value: authService,
      child: MaterialApp(
        // Remove debug banner for cleaner appearance
        debugShowCheckedModeBanner: false,
        // App title shown in task switcher
        title: 'AFO Chat Application',
        // Professional blue theme matching military/official styling
        theme: ThemeData(primarySwatch: Colors.indigo),
        
        // Home screen determined by authentication state
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            // Show loading spinner while checking authentication
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator())
              );
            // If authenticated, show main home screen
            } else if (auth.isAuthenticated) {
              return const HomeScreen(); // This is homescreen.dart - main chat list
            // If not authenticated, show login screen
            } else {
              return const LoginScreen();
            }
          },
        ),
        
        // Route definitions for named navigation throughout the app
        routes: {
          '/login': (_) => const LoginScreen(),       // User authentication
          '/register': (_) => const RegisterScreen(), // New user registration
          '/home': (_) => const HomeScreen(),         // Main chat list screen
          '/profile': (_) => const ProfileScreen(),  // User profile management
          '/google_signin_test': (_) => const GoogleSignInTestScreen(), // Google Sign-In testing
        },
        
        // Dynamic route generation for screens requiring parameters
        onGenerateRoute: (settings) {
          // Chat screen route - requires userId and userName parameters
          if (settings.name == '/chat') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ChatScreen(
                contactId: args['userId'],
                contactName: args['userName'] ?? 'User',
              ),
            );
          } 
          // Call screen route - requires call details and type (voice/video)
          else if (settings.name == '/call') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CallScreen(
                remoteUserId: args['remoteUserId'] ?? 'unknown',
                remoteUserName: args['remoteUserName'] ?? 'Unknown User',
                callType: (args['isVideo'] ?? false) ? CallType.video : CallType.voice,
              ),
            );
          }
          // Return null if route not found (will use default route handling)
          return null;
        },
      ),
    );
  }
}
