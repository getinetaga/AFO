// ============================================================================
// AFO Chat Application - Login Screen
// ============================================================================
// This screen handles user authentication for the AFO (Afaan Oromoo Chat Services)
// application. It provides a clean, professional login interface with:
// - Email/password authentication form
// - Form validation and error handling
// - Navigation to registration screen
// - Google Sign-In integration option
// - Professional blue theme matching the app design
//
// Features:
// - Secure authentication with AuthService
// - Loading states and error feedback
// - Responsive design for various screen sizes
// - Integration with mock authentication system
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'google_signin_test_screen.dart';

/// Login Screen - User Authentication Interface
/// Provides secure login functionality for AFO Chat Services
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Login Screen State - Manages form state and authentication logic
class _LoginScreenState extends State<LoginScreen> {
  // ========================================================================
  // Form Controllers and State Variables
  // ========================================================================
  
  /// Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  /// User input fields
  String _email = '';
  String _password = '';
  
  /// UI state management
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      // Professional blue theme for AFO branding
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('AFO Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login,
                          size: 64,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => _email = v!.trim(),
                          validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: true,
                          onSaved: (v) => _password = v ?? '',
                          validator: (v) => (v != null && v.length >= 6) ? null : 'Min 6 chars',
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) 
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_error != null) const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : () async {
                              final form = _formKey.currentState!;
                              if (!form.validate()) return;
                              form.save();
                              setState(() { _loading = true; _error = null; });
                              try {
                                await auth.login(email: _email, password: _password);
                                // on success, provider will update and navigate automatically
                              } catch (e) {
                                setState(() { _error = e.toString(); });
                              } finally {
                                setState(() { _loading = false; });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _loading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                          child: Text(
                            'Don\'t have an account? Create one',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : () async {
                              setState(() { _loading = true; _error = null; });
                              try {
                                await auth.signInWithGoogle();
                              } catch (e) {
                                setState(() { _error = e.toString(); });
                              } finally {
                                setState(() { _loading = false; });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: SizedBox(
                              width: 20,
                              height: 20,
                              child: Image.asset(
                                'assets/google_logo.png', 
                                width: 20, 
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.account_circle,
                                    size: 20,
                                    color: Colors.red,
                                  );
                                },
                              ),
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add a test button for Google Sign-in
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GoogleSignInTestScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Test Google Sign-in Setup',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
