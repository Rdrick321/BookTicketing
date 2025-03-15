import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/ticket.dart';
import 'package:tixtogo/repositories/ticket_repository.dart';

class AdminTicketPage extends StatefulWidget {
  const AdminTicketPage({super.key});

  @override
  _AdminTicketPageState createState() => _AdminTicketPageState();
}

class _AdminTicketPageState extends State<AdminTicketPage> {
  final TicketRepository _ticketRepository = TicketRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await _ticketRepository.getTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading tickets: $e')));
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String status) async {
    try {
      await _ticketRepository.updateTicketStatus(ticketId, status);
      await _loadTickets(); // Refresh the list after updating
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ticket status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Admin Ticket Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
              ? const Center(
                child: Text(
                  'No tickets found.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final ticket = _tickets[index];
                  return _buildTicketCard(ticket);
                },
              ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reference: ${ticket.referenceNumber}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ticket.status == 'paid' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Movie: ${ticket.movie}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Theater: ${ticket.theater}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Seats: ${ticket.seatNumber}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(ticket.date)}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${ticket.time}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (ticket.status != 'paid')
              ElevatedButton(
                onPressed: () => _updateTicketStatus(ticket.id, 'paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mark as Paid'),
              ),
          ],
        ),
      ),
    );
  }
}
