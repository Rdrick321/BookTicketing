import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/theaters.dart';

class TheaterRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all theaters
  Future<List<Map<String, dynamic>>> getTheaters() async {
    final response = await _supabase
        .from('theaters')
        .select()
        .order('name', ascending: true);

    return response;
  }

  // Get theater by ID
  Future<Map<String, dynamic>> getTheaterById(String id) async {
    final response =
        await _supabase.from('theaters').select().eq('id', id).single();

    return response;
  }

  // Add a new theater
  Future<void> addTheater(Theater theater) async {
    await _supabase.from('theaters').insert(theater.toMap());
  }

  // Update an existing theater
  Future<void> updateTheater(String id, Theater theater) async {
    await _supabase.from('theaters').update(theater.toMap()).eq('id', id);
  }

  // Delete a theater
  Future<void> deleteTheater(String id) async {
    await _supabase.from('theaters').delete().eq('id', id);
  }
}
