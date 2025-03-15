class Ticket {
  final String id;
  final String referenceNumber;
  final String movie;
  final String theater;
  final DateTime date;
  final String time;
  final String seatNumber;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  Ticket({
    required this.id,
    required this.referenceNumber,
    required this.movie,
    required this.theater,
    required this.date,
    required this.time,
    required this.seatNumber,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  // Convert a Ticket object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'movie': movie,
      'theater': theater,
      'date': date.toIso8601String(),
      'time': time,
      'seat_number': seatNumber,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  // Create a Ticket object from a Map
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      referenceNumber: map['reference_number'],
      movie: map['movie'],
      theater: map['theater'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      seatNumber: map['seat_number'],
      paymentMethod: map['payment_method'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: DateTime.parse(map['expires_at']),
    );
  }
}
