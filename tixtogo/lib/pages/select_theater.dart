import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/pages/seats_page.dart';
import 'package:tixtogo/pages/theater_details.dart';

class SelectTheaterScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const SelectTheaterScreen({super.key, required this.movie});

  @override
  _SelectTheaterScreenState createState() => _SelectTheaterScreenState();
}

class _SelectTheaterScreenState extends State<SelectTheaterScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> theaters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTheaters();
  }

  Future<void> fetchTheaters() async {
    final response = await supabase.from('theaters').select();
    setState(() {
      theaters =
          response.map((theater) {
            return {
              "name": theater["name"] ?? "Unknown",
              "location": theater["location"] ?? "Location unavailable",
              "image":
                  theater["image"]?.isNotEmpty == true
                      ? theater["image"]
                      : "https://via.placeholder.com/400x200?text=No+Image",
              "distance": theater["distance"]?.toString() ?? "Unknown distance",
            };
          }).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Select Theater for ${widget.movie['title']}"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: theaters.length,
                itemBuilder: (context, index) {
                  final theater = theaters[index];
                  return TheaterCard(theater: theater, movie: widget.movie);
                },
              ),
    );
  }
}

class TheaterCard extends StatelessWidget {
  final Map<String, dynamic> theater;
  final Map<String, dynamic> movie;

  const TheaterCard({super.key, required this.theater, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      SeatSelectionScreen(movie: movie, theater: theater),
            ),
          );
        },
        child: Card(
          elevation: 6,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => TheaterDetailsModal(
                                theater: theater,
                                movie: movie,
                                onUpdate: () {},
                              ),
                        );
                      },
                      child: const Text("Get Info"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
