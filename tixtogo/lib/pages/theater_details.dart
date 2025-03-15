import 'package:flutter/material.dart';

class TheaterDetailsModal extends StatelessWidget {
  final Map<String, dynamic> theater;
  final Map<String, dynamic> movie;

  const TheaterDetailsModal({
    super.key,
    required this.theater,
    required this.movie,
    required VoidCallback onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Use null-aware operators (??) to provide default values
    String theaterName = theater["name"] ?? "Unknown Theater";
    String location = theater["location"] ?? "Location not available";
    String distance = theater["distance"] ?? "Distance unknown";
    String imageUrl =
        theater["image"] ??
        "https://via.placeholder.com/400x200?text=No+Image"; // Default placeholder image

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder:
          (_, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    theaterName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location Card
                  Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        "Location",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.navigation,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Distance Card
                  Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.directions_walk,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        "Distance",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        distance,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 32,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close modal
                      },
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
