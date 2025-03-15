import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tixtogo/models/seat.dart';
import 'package:tixtogo/pages/payment_screen.dart';
import 'package:tixtogo/repositories/seats_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final Map<String, dynamic> theater;

  const SeatSelectionScreen({
    Key? key,
    required this.movie,
    required this.theater,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late final SeatsRepository _seatsRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool isLoading = true;
  List<List<Seat>> seats = [];
  List<Seat> selectedSeats = [];
  int? selectedDateIndex;
  int? selectedTimeIndex;
  String? selectedDate;
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    _seatsRepository = SeatsRepository();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    try {
      if (selectedDate == null || selectedTime == null) {
        setState(() => isLoading = false);
        return;
      }

      // Get or create showtime and retrieve its ID
      final showtimeId = await _storeSelectedDateAndTime();
      if (showtimeId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error retrieving showtime')),
        );
        return;
      }

      // Load seats using showtimeId
      final seatsData = await _seatsRepository.getSeatsForShowtime(showtimeId);

      final groupedSeats = _groupSeatsByRow(seatsData);
      setState(() {
        seats = groupedSeats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading seats: $e')));
    }
  }

  List<List<Seat>> _groupSeatsByRow(List<Seat> seats) {
    final Map<String, List<Seat>> seatMap = {};
    for (final seat in seats) {
      final row = seat.seatNumber.substring(0, 1);
      seatMap.putIfAbsent(row, () => []).add(seat);
    }
    return seatMap.values.toList()
      ..sort((a, b) => a.first.seatNumber.compareTo(b.first.seatNumber));
  }

  Future<String?> _storeSelectedDateAndTime() async {
    if (selectedDate != null && selectedTime != null) {
      try {
        final response =
            await _supabase
                .from('showtimes')
                .upsert({
                  'date': selectedDate,
                  'time': selectedTime,
                  'movie_id': widget.movie['id'],
                  'theater_id': widget.theater['id'],
                })
                .select('id')
                .single();

        return response['id'] as String?;
      } catch (e) {
        print('Error storing showtime: $e');
        return null;
      }
    }
    return null;
  }

  void _toggleSeatSelection(Seat seat) async {
    if (seat.status != 'available') return;

    try {
      setState(() {
        if (selectedSeats.contains(seat)) {
          selectedSeats.remove(seat);
        } else {
          selectedSeats.add(seat);
        }
      });

      await _seatsRepository.updateSeatStatus(
        seat.id,
        selectedSeats.contains(seat) ? 'reserved' : 'available',
      );
      await _loadSeats();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update seat: $e')));
    }
  }

  int _calculateTotalPrice() {
    return selectedSeats.fold(0, (sum, seat) => sum + seat.price);
  }

  void _navigateToPaymentScreen() {
    // Renamed to match button handler
    if (selectedDate != null &&
        selectedTime != null &&
        selectedSeats.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentScreen(
                movieTitle: widget.movie['title'],
                theaterName: widget.theater['name'],
                selectedDate: selectedDate!,
                selectedTime: selectedTime!,
                selectedSeats:
                    selectedSeats
                        .map((seat) => seat.seatNumber) // Fixed seat mapping
                        .toList(),
                totalPrice: _calculateTotalPrice(), // Use calculated total
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date, time, and seats.')),
      );
    }
  }

  Widget _buildDateSelector() {
    DateTime today = DateTime.now();
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<DateTime> dates = List.generate(
      6,
      (i) => today.add(Duration(days: i)),
    );

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekdays.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedDateIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedDate = DateFormat('yyyy-MM-dd').format(dates[index]);
                  selectedDateIndex = index;
                  _loadSeats();
                });
                _storeSelectedDateAndTime();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.amber : Colors.grey[700],
                foregroundColor: isSelected ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '${weekdays[index]}\n${DateFormat('MM/dd').format(dates[index])}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    List<String> timeSlots = ['12:00 PM', '3:00 PM', '6:00 PM', '9:00 PM'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedTimeIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedTime = timeSlots[index];
                  selectedTimeIndex = index;
                  _loadSeats();
                });
                _storeSelectedDateAndTime();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.amber : Colors.grey[700],
                foregroundColor: isSelected ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(timeSlots[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      appBar: AppBar(
        title: Text('Select Seats - ${widget.movie['title']}'),
        backgroundColor: Colors.black, // Set app bar background color to black
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildDateSelector(),
                  _buildTimeSelector(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'SCREEN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: seats.length,
                      itemBuilder: (context, rowIndex) {
                        final row = seats[rowIndex];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              String.fromCharCode(65 + rowIndex),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Set text color to white
                              ),
                            ),
                            ...row
                                .map((seat) => _buildSeatWidget(seat))
                                .toList(),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _navigateToPaymentScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Confirm ${selectedSeats.length} Seats - ₱${_calculateTotalPrice()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSeatWidget(Seat seat) {
    return GestureDetector(
      onTap: () => _toggleSeatSelection(seat),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _getSeatColor(seat),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            seat.seatNumber.substring(1),
            style: TextStyle(
              color: _getTextColor(seat),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeatColor(Seat seat) {
    if (selectedSeats.contains(seat)) return Colors.blue;
    switch (seat.status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTextColor(Seat seat) {
    return (seat.status == 'available' || selectedSeats.contains(seat))
        ? Colors.white
        : Colors.black;
  }
}
