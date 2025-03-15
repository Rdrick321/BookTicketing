import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/admin_pages/admin_page.dart';
import 'package:tixtogo/auth/auth_service.dart';
import 'package:tixtogo/pages/welcome.dart';
import 'package:tixtogo/pages/login.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;
  final authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    setState(() {
      _isLoading = true;
    });

    // Add a small delay to make sure Supabase auth state is updated
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.amber)),
        )
        // Use StreamBuilder to listen to auth state changes
        : StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final session = snapshot.data!.session;

              // If user is signed in
              if (session != null) {
                // Use FutureBuilder to get user role and decide which page to show
                return FutureBuilder<String>(
                  future: authService.getCurrentUserRole(),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                      );
                    }

                    final role = roleSnapshot.data ?? 'user';

                    // Route based on role
                    if (role == 'admin') {
                      return const AdminPage();
                    } else {
                      return const WelcomePage();
                    }
                  },
                );
              }
            }

            // If user is not signed in, show login page
            return const LoginPage();
          },
        );
  }
}
