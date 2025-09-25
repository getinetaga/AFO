// Test Google Sign-in without backend
// This is a simple test to verify Google Sign-in SDK is working
// Add this method to your AuthService for testing

Future<void> testGoogleSignInOnly() async {
  try {
    // Test Google Sign-in SDK only (no backend call)
    final account = await _googleSignIn.signIn();
    if (account == null) {
      print('❌ Google sign-in was cancelled');
      return;
    }
    
    print('✅ Google sign-in successful!');
    print('📧 Email: ${account.email}');
    print('👤 Display Name: ${account.displayName}');
    print('🆔 ID: ${account.id}');
    
    final auth = await account.authentication;
    print('🔑 Access Token: ${auth.accessToken?.substring(0, 50)}...');
    print('🎫 ID Token: ${auth.idToken?.substring(0, 50)}...');
    
    // Clean up - sign out after test
    await _googleSignIn.signOut();
    print('🚪 Signed out successfully');
    
  } catch (e) {
    print('❌ Google Sign-in test failed: $e');
  }
}
