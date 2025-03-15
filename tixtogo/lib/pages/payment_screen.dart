import 'package:flutter/material.dart';
import 'package:tixtogo/pages/welcome.dart';
import 'package:uuid/uuid.dart';
import 'dart:math'; // Import to generate random numbers
import 'package:flutter/services.dart';
import 'package:tixtogo/models/ticket.dart'; // Import the Ticket model
import 'package:tixtogo/repositories/ticket_repository.dart'; // Import the TicketRepository

class PaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String theaterName;
  final String selectedDate;
  final String selectedTime;
  final List<String> selectedSeats;
  final int totalPrice;

  const PaymentScreen({
    super.key,
    required this.movieTitle,
    required this.theaterName,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSeats,
    required this.totalPrice,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TicketRepository _ticketRepository = TicketRepository();
  String? selectedPaymentMethod;
  int dynamicTotalPrice = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmBooking() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    try {
      // Generate a random reference number (6 digits)
      String referenceNumber = (100000 + Random().nextInt(900000)).toString();

      // Create a new Ticket object
      final ticket = Ticket(
        id: const Uuid().v4(),
        referenceNumber: referenceNumber,
        movie: widget.movieTitle,
        theater: widget.theaterName,
        date: DateTime.parse(widget.selectedDate),
        time: widget.selectedTime,
        seatNumber: widget.selectedSeats.join(', '),
        paymentMethod: selectedPaymentMethod!,
        status: 'pending', // Default status is 'pending'
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          const Duration(minutes: 30),
        ), // Expires in 30 minutes
      );

      // Save the ticket to the database
      await _ticketRepository.addTicket(ticket);

      print('Ticket saved successfully: $referenceNumber');

      // Show modal after successful payment
      _showReferenceNumberModal(referenceNumber);
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
    }
  }

  void _showReferenceNumberModal(String referenceNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Payment Successful!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 15),
              const Text(
                'Your Reference Number:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SelectableText(
                  referenceNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: referenceNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reference number copied!')),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.black),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                  // Navigate to WelcomePage and clear the stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              WelcomePage(), // Replace with your WelcomePage
                    ),
                    (Route<dynamic> route) => false, // Clear the stack
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movie: ${widget.movieTitle}',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Theater: ${widget.theaterName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Date: ${widget.selectedDate}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Time: ${widget.selectedTime}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Seats: ${widget.selectedSeats.join(', ')}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Divider(color: Colors.white54),
                    Text(
                      'Total Price: ₱${widget.totalPrice}',
                      style: const TextStyle(fontSize: 18, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildPaymentOption('Cash at Counter', Icons.money),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber),
        title: Text(method, style: const TextStyle(color: Colors.white)),
        tileColor:
            selectedPaymentMethod == method ? Colors.amber : Colors.blueGrey,
        onTap: () => setState(() => selectedPaymentMethod = method),
      ),
    );
  }
}
