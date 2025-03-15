import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/ticket.dart';

class TicketRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all tickets
  Future<List<Ticket>> getTickets() async {
    try {
      final response = await _supabase.from('ticket').select('*');
      return (response as List)
          .map<Ticket>((map) => Ticket.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  // Fetch a ticket by reference number
  Future<Ticket?> getTicketByReferenceNumber(String referenceNumber) async {
    try {
      final response =
          await _supabase
              .from('ticket')
              .select('*')
              .eq('reference_number', referenceNumber)
              .single();

      return Ticket.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch ticket: $e');
    }
  }

  // Add a new ticket
  Future<void> addTicket(Ticket ticket) async {
    try {
      await _supabase.from('ticket').insert(ticket.toMap());
    } catch (e) {
      throw Exception('Failed to add ticket: $e');
    }
  }

  // Update a ticket's status
  Future<void> updateTicketStatus(String id, String status) async {
    try {
      await _supabase.from('ticket').update({'status': status}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  // Delete a ticket
  Future<void> deleteTicket(String id) async {
    try {
      await _supabase.from('ticket').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  // Fetch expired tickets
  Future<List<Ticket>> getExpiredTickets() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('ticket')
          .select('*')
          .lt('expires_at', now) // Tickets where expires_at is less than now
          .eq('status', 'pending'); // Only pending tickets

      return (response as List)
          .map<Ticket>((map) => Ticket.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expired tickets: $e');
    }
  }
}
