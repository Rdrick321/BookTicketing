class Seat {
  final String id;
  final String seatNumber;
  final int price;
  final DateTime createdAt;
  final String status;

  Seat({
    required this.id,
    required this.seatNumber,
    required this.price,
    required this.createdAt,
    required this.status,
  });

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id'] as String,
      seatNumber: map['seat_number'] as String,
      price: map['price'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seat_number': seatNumber,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
