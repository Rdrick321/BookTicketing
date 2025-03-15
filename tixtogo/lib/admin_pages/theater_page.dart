import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_theaters.dart'; // Import the admin theater management page
import 'admin_theaterdetails.dart'; // Import the admin theater details page

class TheaterScreen extends StatefulWidget {
  const TheaterScreen({super.key});

  @override
  State<TheaterScreen> createState() => TheaterScreenState();
}

class TheaterScreenState extends State<TheaterScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> theaters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTheaters();
  }

  Future<void> fetchTheaters() async {
    try {
      final response = await supabase.from('theaters').select();
      setState(() {
        theaters =
            response.map((theater) {
              return {
                "id": theater["id"], // Add ID for editing/deleting
                "name": theater["name"] ?? "Unknown",
                "location": theater["location"] ?? "Location unavailable",
                "image":
                    theater["image"]?.isNotEmpty == true
                        ? theater["image"]
                        : "https://via.placeholder.com/400x200?text=No+Image",
                "distance":
                    theater["distance"]?.toString() ?? "Unknown distance",
                "seating_capacity":
                    theater["seating_capacity"]?.toString() ?? "0",
              };
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading theaters: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Theaters"), // Updated title for admin
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminTheaters()),
              ).then((_) => fetchTheaters()); // Refresh list after adding
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              )
              : theaters.isEmpty
              ? const Center(
                child: Text(
                  "No theaters available",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: theaters.length,
                itemBuilder: (context, index) {
                  final theater = theaters[index];
                  return TheaterCard(
                    theater: theater,
                    onUpdate:
                        fetchTheaters, // Pass fetchTheaters for refreshing
                  );
                },
              ),
    );
  }
}

class TheaterCard extends StatelessWidget {
  final Map<String, dynamic> theater;
  final VoidCallback onUpdate;

  const TheaterCard({super.key, required this.theater, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 6,
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    theater["image"]!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        "https://via.placeholder.com/400x200?text=No+Image",
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theater["name"]!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${theater["distance"]} away",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            // Navigate to AdminTheaterdetails
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AdminTheaterdetails(
                                      theater: theater,
                                      onUpdate: onUpdate,
                                    ),
                              ),
                            );
                          },
                          child: const Text("View Details"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _deleteTheater(context, theater["id"]);
                          },
                          child: const Text("Delete"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTheater(BuildContext context, String theaterId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('theaters').delete().eq('id', theaterId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theater deleted successfully!')),
      );
      onUpdate(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting theater: ${e.toString()}')),
      );
    }
  }
}
