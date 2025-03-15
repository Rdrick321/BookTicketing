import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/seat.dart';

class SeatsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Seat>> getSeatsForShowtime(String movieId) async {
    try {
      final response = await _supabase
          .from('seats')
          .select()
          .order('seat_number', ascending: true);

      return response.map<Seat>((map) => Seat.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load seats: ${e.message}');
    }
  }

  Future<void> updateSeatStatus(String seatId, String newStatus) async {
    try {
      final response =
          await _supabase
              .from('seats')
              .update({'status': newStatus})
              .eq('id', seatId)
              .select()
              .single();

      if (response['status'] != newStatus) {
        throw Exception('Seat status update verification failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update seat status: ${e.message}');
    }
  }

  Future<void> reserveSeats(List<String> seatIds) async {
    try {
      await _supabase
          .from('seats')
          .update({'status': 'reserved'})
          .inFilter('id', seatIds);
    } on PostgrestException catch (e) {
      throw Exception('Failed to reserve seats: ${e.message}');
    }
  }

  Future<List<Seat>> getSeatStatusBatch(List<String> seatIds) async {
    try {
      final response = await _supabase
          .from('seats')
          .select()
          .inFilter('id', seatIds);

      return response.map<Seat>((map) => Seat.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get seat status: ${e.message}');
    }
  }
}
