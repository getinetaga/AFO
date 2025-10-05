/// AFO Chat Application - Google Sign-In Test Screen
/// AFO: Afaan Oromoo Chat Services
/// 
/// This screen provides Google Sign-In testing functionality for the AFO
/// chat application, facilitating authentication testing for the Afaan Oromoo 
/// community platform. Features include:
/// 
/// - Google Sign-In integration testing and validation
/// - Authentication flow debugging and error handling
/// - User account information display after successful sign-in
/// - Professional testing interface with clear status indicators
/// - Integration with AuthService for Google authentication
/// - Development and testing support for OAuth implementation
/// 
/// This screen is primarily used for development and testing purposes
/// to ensure proper Google authentication integration in the AFO platform.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class GoogleSignInTestScreen extends StatelessWidget {
  const GoogleSignInTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Google Sign-In Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Testing Google Sign-in...')),
                  );
                  
                  // Use the test method instead of full authentication
                  await auth.testGoogleSignInOnly();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Google Sign-in test successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Show success dialog with user info
                  final user = auth.user;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Google Sign-in Test Successful!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user?['email'] ?? 'N/A'}'),
                          Text('Name: ${user?['displayName'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          const Text('✅ Google Sign-in SDK is working correctly!'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          child: const Text('Go to Home'),
                        ),
                      ],
                    ),
                  );
                  
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Google Sign-in test failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Test Google Sign-In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
