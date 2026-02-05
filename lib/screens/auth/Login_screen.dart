import 'package:flutter/material.dart';
import 'package:guptik/screens/Home/home_screen.dart';
import 'package:guptik/screens/auth/signup_screen.dart';
import 'package:guptik/services/auth/auth_service.dart';
import 'package:guptik/widgets/my_button.dart';
import 'package:guptik/widgets/snack_bar.dart';


// ignore_for_file: file_names
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;
  bool ispasswordhidden = true;

  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
  String? result = await _authService.login(email, password);
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (result == null) {
      showSnackBar(context, "Login successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Login failed: $result");
    }
  }

  Future<void> _signInWithGoogle() async {
    showSnackBar(context, "Google sign-in not configured yet. Please use email/password login.");
    return;
    
    // Google OAuth implementation (disabled until configured in Supabase)
    /*
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    
    String? result = await _authService.signInWithGoogle();
    
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    
    if (result == null) {
      showSnackBar(context, "Google sign-in successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      showSnackBar(context, "Google sign-in failed: $result");
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            "assets/images/images2.png",
            fit: BoxFit.cover,
          ),
          // Glassmorphic login card
          Center(
            child: Container(
              width: 370,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Color.fromARGB(128, 0, 0, 0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color.fromARGB(51, 255, 255, 255)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(77, 0, 0, 0),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Login with',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Login using email or social media',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _signInWithGoogle,
                        icon: Image.asset(
                          'assets/images/google.png',
                          height: 24,
                        ),
                        label: Text('Google'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: Icon(Icons.apple, size: 24),
                        label: Text('Apple'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Or', style: TextStyle(color: Colors.white54)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color.fromARGB(26, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: ispasswordhidden,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color.fromARGB(26, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            ispasswordhidden = !ispasswordhidden;
                          });
                        },
                        icon: Icon(ispasswordhidden ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
          isLoading
            ? Center(child: CircularProgressIndicator())
            : SizedBox(child: MyButton(onTap: _login, buttontext: "Login")),
                  SizedBox(height: 20),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupScreen()),
                          );
                        },
                        child: Text(
                          "Sign up here",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  
        
         