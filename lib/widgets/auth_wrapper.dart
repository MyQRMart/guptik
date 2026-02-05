import 'package:flutter/material.dart';
import 'package:guptik/screens/Home/home_screen.dart';
import 'package:guptik/screens/auth/Login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          );
        }

        // Check if user is authenticated
        final Session? session = Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          // User is logged in, show home screen with error boundary
          return Builder(
            builder: (context) {
              try {
                return const HomeScreen();
              } catch (e) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading home screen: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Force rebuild
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        } else {
          // User is not logged in, show login screen
          return const LoginScreen();
        }
      },
    );
  }
}