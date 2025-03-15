import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tixtogo/admin_pages/admin_movies.dart';
import 'package:tixtogo/admin_pages/admin_theaters.dart';
import 'package:tixtogo/admin_pages/admin_ticketpage.dart';
import 'package:tixtogo/admin_pages/theater_page.dart';
import 'package:tixtogo/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final authService = AuthService();
  int _currentCarouselIndex = 0;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> movies = [];
  List<Map<String, dynamic>> comingSoonMovies = [];
  List<Map<String, dynamic>> DoneShowingMovies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadComingSoonMovies();
    _loadDoneShowingMovies();
  }

  void logout() async {
    await authService.signOut();
  }

  String getImageUrl(String imageName) {
    return Supabase.instance.client.storage
        .from('movies') // Bucket name
        .getPublicUrl(
          imageName.replaceAll(
            "https://mkynvxupnliitwaxnlne.supabase.co/storage/v1/object/public/movies/",
            "",
          ),
        );
  }

  Future<void> _loadMovies() async {
    try {
      final response = await Supabase.instance.client
          .from('movies')
          .select()
          .eq('status', 'Showing'); // ✅ Filter only "Coming Soon" movies

      setState(() {
        movies =
            response.map<Map<String, dynamic>>((movie) {
              return {
                'id': movie['id'],
                'title': movie['title'],
                'year': movie['year'],
                'duration': movie['duration'],
                'rating': movie['rating'],
                'genre': movie['genre'],
                'description': movie['description'],
                'director': movie['director'],
                'cast': movie['cast'],
                'image': getImageUrl(movie['image']), // Use function to get URL
                'status': movie['status'], // ✅ Ensure status is included
                'release_date': movie['release_date'],
              };
            }).toList();
      });

      // Debugging: Print each movie's image URL
      for (var movie in movies) {
        print('Image URL: ${movie['image']}');
      }
    } catch (e) {
      print('Error loading movies: $e');
    }
  }

  void viewDetails(Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMovieDetailsSheet(movie),
    );
  }

  void _editMovie(Map<String, dynamic> movie) {
    // Navigate to the edit page with the movie data
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminMovies(movieToEdit: movie)),
    ).then((_) {
      // Refresh movies list when returning from edit page
      _loadMovies();
      _loadComingSoonMovies();
    });
  }

  // Method to show delete confirmation dialog
  void _confirmDeleteMovie(BuildContext context, Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${movie['title']}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.amber),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                _deleteMovie(movie); // Call delete function
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Method to delete the movie from the database
  Future<void> _deleteMovie(Map<String, dynamic> movie) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Color(0xFF1E1E1E),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 20),
                Text(
                  'Deleting movie...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      // Delete the movie from Supabase
      final response = await Supabase.instance.client
          .from('movies')
          .delete()
          .eq('id', movie['id']);

      // Close the loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie['title']} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh movie lists
      _loadMovies();
      _loadComingSoonMovies();
    } catch (e) {
      // Close the loading dialog if open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error deleting movie: $e');
    }
  }

  Widget _buildMovieDetailsSheet(Map<String, dynamic>? movie) {
    if (movie == null || movie.isEmpty) {
      return Center(
        child: Text(
          "No Movie Data Available",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Movie Poster
                      Container(
                        height: 250,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (movie['image'] != null &&
                                movie['image'].isNotEmpty)
                              Image.network(
                                movie['image'],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _errorImage(),
                              )
                            else
                              _errorImage(),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black],
                                    stops: [0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Movie Title & Info
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie['title'] ?? 'Unknown Title',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),

                            Row(
                              children: [
                                _infoBadge(movie['year'] ?? 'Unknown Year'),
                                SizedBox(width: 10),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  movie['rating']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  movie['duration'] ?? 'Unknown Duration',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Synopsis
                            Text(
                              'Synopsis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              movie['description'] ??
                                  'No description available.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),

                            SizedBox(height: 20),

                            // Genre Info
                            _buildInfoRow(
                              'Genre',
                              movie['genre'] is List
                                  ? (movie['genre'] as List).join(', ')
                                  : movie['genre'] ?? 'Unknown',
                            ),
                            SizedBox(height: 20),

                            // Director Info
                            _buildInfoRow(
                              'Director',
                              movie['director'] ?? 'Unknown',
                            ),
                            SizedBox(height: 10),

                            // Cast Info
                            _buildInfoRow(
                              'Cast',
                              movie['cast'] ?? 'No cast info',
                            ),

                            SizedBox(height: 30),

                            // Add Edit and Delete buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Edit Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                    ); // Close the bottom sheet
                                    _editMovie(movie); // Call edit function
                                  },
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 20),

                                // Delete Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _confirmDeleteMovie(
                                      context,
                                      movie,
                                    ); // Show confirmation dialog
                                  },
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget for Error Image
  Widget _errorImage() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.white38),
    );
  }

  // Helper Widget for Badges
  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 72, 54, 0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildHomeContent(), TheaterScreen(), AdminTicketPage()],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Check which tab is currently selected
          if (_selectedIndex == 0) {
            // Home tab is selected, navigate to AdminMovies
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminMovies()),
            );
          } else if (_selectedIndex == 1) {
            // Theater tab is selected, navigate to AdminTheaters
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminTheaters()),
            );
          } else if (_selectedIndex == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminTicketPage()),
            );
          }
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position of FAB
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle("Categories"),
            _buildCategoryGrid(),
            const SizedBox(height: 10),
            _buildSectionTitle("Now Showing"),
            _buildCarouselSlider(),
            const SizedBox(height: 10),
            _buildSectionTitle("Coming Soon"),
            _buildComingSoonList(),
            const SizedBox(height: 10),
            _buildSectionTitle("Done Showing"),
            _buildDoneShowingSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex == index) return;

          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            activeIcon: Icon(Icons.movie_outlined),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.theaters),
            activeIcon: Icon(Icons.theaters_outlined),
            label: 'Theaters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_outlined),
            activeIcon: Icon(Icons.local_activity),
            label: 'Tickets',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Tix',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            TextSpan(
              text: 'ToGo',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      elevation: 0,
      toolbarHeight: 50,
      actions: [
        IconButton(
          onPressed: logout,
          icon: const Icon(
            Icons.logout_outlined,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Logout',
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("View All $title")));
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'See All',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<String> categories = [
      'Action',
      'Comedy',
      'Drama',
      'Fantasy',
      'Horror',
      'Sci-Fi',
      'Thriller',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 5, bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Selected ${categories[index]}")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.amber, width: 1),
                ),
              ),
              child: Text(
                categories[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider.builder(
      options: CarouselOptions(
        autoPlay: true,
        viewportFraction: 0.40,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enlargeFactor: 0.1,
        autoPlayInterval: Duration(seconds: 3),
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      itemCount: movies.length,
      itemBuilder: (context, index, realIndex) {
        final movie = movies[index];

        return GestureDetector(
          onTap: () {
            viewDetails(movie);
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Movie Image
                  if (movie['image'] != null && movie['image'].isNotEmpty)
                    Image.network(
                      movie['image'],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => _errorImage(),
                    )
                  else
                    _errorImage(),

                  // Dark Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black,
                          ],
                          stops: [0.0, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Movie Details (Title, Year, Rating)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _infoBadge(movie['year'] ?? 'Unknown Year'),
                            SizedBox(width: 6),
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 2),
                            Text(
                              '${movie['rating'] ?? "N/A"}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          movie['title'] ?? "No Title",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          movie['genre'] is List
                              ? (movie['genre'] as List).join(', ')
                              : movie['genre'] ?? 'Unknown Genre',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadComingSoonMovies() async {
    try {
      final response = await Supabase.instance.client
          .from('movies')
          .select()
          .eq('status', 'Coming Soon'); // ✅ Filter only "Coming Soon" movies

      setState(() {
        comingSoonMovies =
            response.map<Map<String, dynamic>>((movie) {
              return {
                'id': movie['id'],
                'title': movie['title'],
                'year': movie['year'],
                'rating': movie['rating'],
                'duration': movie['duration'],
                'image': movie['image'],
                'description': movie['description'],
                'director': movie['director'],
                'cast': movie['cast'],
                'genre': movie['genre'],
                'status': movie['status'], // ✅ Ensure status is included
                'release_date': movie['release_date'],
              };
            }).toList();
      });

      print('Coming Soon Movies Loaded: ${comingSoonMovies.length}');
    } catch (e) {
      print('Error fetching coming soon movies: $e');
    }
  }

  Future<void> _loadDoneShowingMovies() async {
    try {
      final response = await Supabase.instance.client
          .from('movies')
          .select()
          .eq('status', 'Done Showing'); // ✅ Filter only "Done Showing" movies

      setState(() {
        DoneShowingMovies =
            response.map<Map<String, dynamic>>((movie) {
              return {
                'id': movie['id'],
                'title': movie['title'],
                'year': movie['year'],
                'rating': movie['rating'],
                'duration': movie['duration'],
                'image': movie['image'],
                'description': movie['description'],
                'director': movie['director'],
                'cast': movie['cast'],
                'genre': movie['genre'],
                'status': movie['status'], // ✅ Ensure status is included
                'release_date': movie['release_date'],
              };
            }).toList();
      });

      print('Coming Soon Movies Loaded: ${DoneShowingMovies.length}');
    } catch (e) {
      print('Error fetching coming soon movies: $e');
    }
  }

  Widget _buildDoneShowingSlider() {
    return CarouselSlider.builder(
      options: CarouselOptions(
        autoPlay: true,
        viewportFraction: 0.40,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enlargeFactor: 0.1,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      itemCount: DoneShowingMovies.length,
      itemBuilder: (context, index, realIndex) {
        final movie = DoneShowingMovies[index];

        return GestureDetector(
          onTap: () {
            // Show movie details when the card is tapped
            viewDetails(movie);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Movie Image
                      Positioned.fill(
                        child: Image.network(
                          movie['image']!, // Ensure this is a valid URL
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      // Dark Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                                Colors.black,
                              ],
                              stops: const [0.0, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Movie Details (Title, Year, Rating)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    movie['year'] ?? "Unknown Year",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${movie['rating'] ?? "N/A"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Movie Title
                            Text(
                              movie['title'] ?? "No Title",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Genre
                            Text(
                              movie['genre'] is List
                                  ? (movie['genre'] as List).join(
                                    ', ',
                                  ) // If genre is an array
                                  : movie['genre'] ?? 'Unknown Genre',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComingSoonList() {
    return CarouselSlider.builder(
      options: CarouselOptions(
        autoPlay: true,
        viewportFraction: 0.40,
        enlargeCenterPage: true,
        enlargeFactor: 0.1,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
      itemCount: comingSoonMovies.length,
      itemBuilder: (context, index, realIndex) {
        final movie = comingSoonMovies[index];

        return GestureDetector(
          onTap: () {
            // Show movie details when the card is tapped
            viewDetails(movie);
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      movie['image'], // Use fetched image URL
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie['release_date'] ?? "TBA",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
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
          ),
        );
      },
    );
  }
}
