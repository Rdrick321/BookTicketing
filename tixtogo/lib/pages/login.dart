import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tixtogo/admin_pages/admin_page.dart';
import 'package:tixtogo/auth/auth_service.dart';
import 'package:tixtogo/pages/register.dart';
import 'package:tixtogo/pages/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Get Auth Service
  final AuthService _authService = AuthService();

  // Text Controllers
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Login button pressed
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Route based on user role
      final role = response['role'];
      if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo at the Top
                Image.asset(
                  'assets/images/Tix.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Login Card
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Login Title
                                const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Email is required";
                                    }
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    ).hasMatch(value)) {
                                      return "Enter a valid email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Password Field
                                TextFormField(
                                  obscureText: obscureText,
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureText
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscureText = !obscureText;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? "Password is required"
                                              : null,
                                ),
                                const SizedBox(height: 20),

                                // Error Message
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                _signIn();
                                              }
                                            },
                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text("Login"),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Don't have an account? Sign Up
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't Have An Account? ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Sign Up Now",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // OR Sign Up With
                                const Text(
                                  "Or sign up with",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Social Media Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _socialButton(
                                      FontAwesomeIcons.facebook,
                                      Colors.blue,
                                      () => _socialLogin('facebook'),
                                    ),
                                    const SizedBox(width: 15),
                                    _socialButton(
                                      FontAwesomeIcons.google,
                                      Colors.red,
                                      () => _socialLogin('google'),
                                    ),
                                    const SizedBox(width: 15),
                                    _socialButton(
                                      FontAwesomeIcons.linkedin,
                                      Colors.blueAccent,
                                      () => _socialLogin('linkedin'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _socialLogin(String provider) {
    // Placeholder for social login functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$provider login not implemented yet")),
    );
  }
}
