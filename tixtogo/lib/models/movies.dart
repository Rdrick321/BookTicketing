class Movies {
  final String title;
  final String year;
  final double rating;
  final String duration;
  final String description;
  final String image;
  final String cast;
  final String director;
  final String genre;
  final String status;
  final DateTime releaseDate;
  final String? id;

  Movies({
    required this.title,
    required this.year,
    required this.rating,
    required this.duration,
    required this.description,
    required this.image,
    required this.cast,
    required this.director,
    required this.genre,
    required this.status,
    required this.releaseDate,
    this.id,
  });

  // Convert a Module object into a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'year': year,
      'rating': rating,
      'duration': duration,
      'description': description,
      'image': image,
      'cast': cast,
      'director': director,
      'genre': genre,
      'status': status,
      'release_date': releaseDate.toIso8601String(),
      if (id != null) 'id': id,
    };
  }

  // Create a Module object from a Map
  factory Movies.fromMap(Map<String, dynamic> map) {
    return Movies(
      title: map['title'],
      year: map['year'],
      rating: map['rating'],
      duration: map['duration'],
      description: map['description'],
      image: map['image'],
      cast: map['cast'],
      director: map['director'],
      genre: map['genre'],
      status: map['status'],
      releaseDate: DateTime.parse(map['release_date']),
      id: map['id'],
    );
  }
}
