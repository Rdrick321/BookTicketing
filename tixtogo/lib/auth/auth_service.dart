import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Create a regular user with the default "user" role
  Future<AuthResponse> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'user', // Set default role as user
      },
    );

    // After signup, create an entry in the profiles table if it doesn't already exist
    if (res.user != null) {
      final existingProfile =
          await supabase
              .from('profiles')
              .select()
              .eq('id', res.user!.id)
              .maybeSingle();

      if (existingProfile == null) {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': 'user',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return res;
  }

  // Sign in method that returns the user role
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    String role = 'user'; // Default role

    if (res.user != null) {
      // Fetch user role from profiles table
      final data =
          await supabase
              .from('profiles')
              .select('role')
              .eq('id', res.user!.id)
              .single();

      if (data != null && data['role'] != null) {
        role = data['role'];
      }
    }

    return {'response': res, 'role': role};
  }

  // Get the current user's role
  Future<String> getCurrentUserRole() async {
    final User? user = supabase.auth.currentUser;

    if (user == null) {
      return '';
    }

    try {
      final data =
          await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();

      return data['role'] ?? 'user';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user'; // Default to user role if error
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
