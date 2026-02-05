import 'package:flutter/material.dart';
import 'package:guptik/screens/auth/Login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  //sign up function

  Future<String?> signup(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        password: password,
        email: email,
      );
      if (response.user != null) {
        return null; // indicates success
      }
      return "Invalid email or password";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error:$e";
    }
  }
// login function
  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user != null) {
        return null; // indicates success
      }
      return "An unknown error occurred";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error:$e";
    }
  }
  
  // Google sign-in function
  Future<String?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.metafly://login',
      );
      return null; // indicates success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }
  
  // function to Logout
  Future<void> logout(BuildContext context) async {
    try {
      await _client.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }
}