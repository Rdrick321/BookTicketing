import 'package:flutter/material.dart';
import 'package:tixtogo/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final authService = AuthService();

  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController =
      TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool obscureText = true;
  bool confObscureText = true;

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await authService.signUp(
        emailController.text.trim(),
        passwordController.text,
        fnameController.text.trim(),
        lnameController.text.trim(),
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
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
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/Tix.png', height: 100),
                      const SizedBox(height: 10),
                      Text(
                        "Create Account",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        fnameController,
                        'First Name',
                        Icons.person_outline,
                      ),
                      _buildTextField(
                        lnameController,
                        'Last Name',
                        Icons.person_outline,
                      ),
                      _buildTextField(
                        emailController,
                        'Email',
                        Icons.email_outlined,
                        TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        passwordController,
                        'Password',
                        Icons.lock_outline,
                        TextInputType.text,
                        obscureText,
                        () {
                          setState(() => obscureText = !obscureText);
                        },
                      ),
                      _buildTextField(
                        confirmpasswordController,
                        'Confirm Password',
                        Icons.lock_outline,
                        TextInputType.text,
                        confObscureText,
                        () {
                          setState(() => confObscureText = !confObscureText);
                        },
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : signUp,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  )
                                  : const Text("Sign Up"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              "Login Now",
                              style: TextStyle(
                                color: Colors.blue,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon:
              toggleObscure != null
                  ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: toggleObscure,
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator:
            (value) =>
                (value == null || value.isEmpty) ? '$label is required' : null,
      ),
    );
  }
}
