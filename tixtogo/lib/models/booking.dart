class Booking {
  final String id;
  final String userId;
  final String showtimeId;
  final String totalPrice;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  // Convert a Booking object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'showtime_id': showtimeId,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a Booking object from a Map
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      userId: map['user_id'],
      showtimeId: map['showtime_id'],
      totalPrice: map['total_price'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
