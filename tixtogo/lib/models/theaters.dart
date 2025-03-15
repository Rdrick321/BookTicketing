class Theater {
  final String? id;
  final String name;
  final String distance;
  final String image;
  final String location;
  final String seatingCapity;

  Theater({
    this.id,
    required this.name,
    required this.distance,
    required this.image,
    required this.location,
    required this.seatingCapity,
  });

  factory Theater.fromMap(Map<String, dynamic> map) {
    return Theater(
      id: map['id'],
      name: map['name'],
      distance: map['distance'],
      image: map['image'],
      location: map['location'],
      seatingCapity: map['seating_capacity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'distance': distance,
      'image': image,
      'location': location,
      'seating_capacity': seatingCapity,
    };
  }
}
