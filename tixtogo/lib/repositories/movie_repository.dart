import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/movies.dart';

class MovieRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all movies
  Future<List<Movies>> getMovies() async {
    try {
      final response = await _supabase.from('movies').select('*');
      return (response as List)
          .map<Movies>((map) => Movies.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch movies: $e');
    }
  }

  // Add a new movie
  Future<void> addMovie(Movies movie) async {
    try {
      await _supabase.from('movies').insert(movie.toMap());
    } catch (e) {
      throw Exception('Failed to add movie: $e');
    }
  }

  // Update a movie
  Future<void> updateMovie(String movieId, Movies movie) async {
    try {
      await _supabase
          .from('movies')
          .update(movie.toMap()) // Use toMap() for consistency
          .eq('id', movieId);
    } catch (e) {
      throw Exception('Failed to update movie: $e');
    }
  }

  // Delete a movie
  Future<void> deleteMovie(String id) async {
    try {
      await _supabase.from('movies').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete movie: $e');
    }
  }
}
