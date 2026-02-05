import 'package:flutter/material.dart';
import 'package:guptik/screens/auth/Login_screen.dart';
import 'package:guptik/services/auth/auth_service.dart';
import 'package:guptik/widgets/my_button.dart';
import 'package:guptik/widgets/snack_bar.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;
  bool ispasswordhidden = true;
  bool isconfirmpasswordhidden = true;

  Future<void> signUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    
    // Validate passwords match
    if (password != confirmPassword) {
      if (!mounted) return;
      showSnackBar(context, "Passwords do not match!");
      return;
    }
    
    // Example: validate email format
    if (!email.contains(".com")) {
      if (!mounted) return;
      showSnackBar(context, "Invalid email. It must contain .com ");
      return;
    }
    setState(() {
      isLoading = true;
    });
    String? result = await _authService.signup(email, password);
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (result == null) {
      showSnackBar(context, "Signup successful! Now turn to Login");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Signup failed: $result");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Image.asset(
                "assets/images/images.png",
                width: double.maxFinite,
                height: 500,  
                fit: BoxFit.cover,
              ),
              // input fields for email, 
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              //password
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      ispasswordhidden = !ispasswordhidden;
                    });
                  },
                  icon: Icon(ispasswordhidden ? Icons.visibility_off :
                    Icons.visibility),
                  ),
                ),
                obscureText: ispasswordhidden,
              ),
              SizedBox(height: 20),
              //confirm password
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      isconfirmpasswordhidden = !isconfirmpasswordhidden;
                    });
                  },
                  icon: Icon(isconfirmpasswordhidden ? Icons.visibility_off :
                    Icons.visibility),
                  ),
                ),
                obscureText: isconfirmpasswordhidden,
              ),
              SizedBox(height: 20),
              isLoading
                  ? Center(child: CircularProgressIndicator(),)
                  :
              SizedBox(child: MyButton(onTap: signUp, buttontext: "Sign Up")),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 18),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      " Login here",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  
        
         