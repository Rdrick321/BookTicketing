import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tixtogo/auth/auth_service.dart';
import 'package:tixtogo/pages/Edit_profile.dart';
import 'package:tixtogo/pages/ticket_page.dart';
import 'package:tixtogo/pages/select_theater.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final authService = AuthService();
  int _currentCarouselIndex = 0;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> movies = [];
  List<Map<String, dynamic>> comingSoonMovies = [];
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadComingSoonMovies();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

      setState(() {
        userProfile = response;
      });
    }
  }

  void logout() async {
    await authService.signOut();
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    userProfile?['avatar_url'] != null
                        ? NetworkImage(userProfile!['avatar_url'])
                        : AssetImage('assets/placeholder.png') as ImageProvider,
              ),
              SizedBox(height: 10),
              Text(
                '${userProfile?['first_name'] ?? 'First Name'} ${userProfile?['last_name'] ?? 'Last Name'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EditProfilePage(userProfile: userProfile),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: logout,
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void bookTicket(String movieTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking ticket for $movieTitle...")),
    );
  }

  void viewDetails(Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMovieDetailsSheet(movie),
    );
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
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ✅ Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
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
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Movie Poster
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            movie['image'] != null && movie['image'].isNotEmpty
                                ? Image.network(
                                  movie['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _errorImage(),
                                )
                                : _errorImage(),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black],
                                  stops: const [0.6, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ Movie Title & Info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie['title'] ?? 'Unknown Title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                _infoBadge(movie['year'] ?? 'Unknown Year'),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  movie['rating']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Text(
                                  movie['duration'] ?? 'Unknown Duration',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ✅ Synopsis
                            const Text(
                              'Synopsis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              movie['description'] ??
                                  'No description available.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ✅ Genre Info
                            _buildInfoRow(
                              'Genre',
                              movie['genre'] is List
                                  ? (movie['genre'] as List).join(
                                    ', ',
                                  ) // If genre is an array
                                  : movie['genre'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 20),

                            // ✅ Director Info
                            _buildInfoRow(
                              'Director',
                              movie['director'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 10),

                            // ✅ Cast Info
                            _buildInfoRow(
                              'Cast',
                              movie['cast'] ?? 'No cast info',
                            ),

                            const SizedBox(height: 30),

                            // ✅ Book Ticket Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  ); // Close the bottom sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              SelectTheaterScreen(movie: movie),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Book Ticket',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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

  // ✅ Helper Widget for Error Image
  Widget _errorImage() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.white38),
    );
  }

  // ✅ Helper Widget for Badges
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
        children: [_buildHomeContent(), const TicketsPage()],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            _buildMovieActionButtons(),
            const SizedBox(height: 10),
            _buildSectionTitle("Coming Soon"),
            _buildComingSoonList(),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
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
          onPressed: () => _showProfileDialog(context),
          icon: const Icon(Icons.menu, color: Colors.white, size: 20),
          tooltip: 'Menu',
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
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      itemCount: movies.length,
      itemBuilder: (context, index, realIndex) {
        final movie = movies[index];

        return LayoutBuilder(
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
                    // Movie Details (Title, Year, Rating, Genre)
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

                          // ✅ Movie Title
                          Text(
                            movie['title'] ?? "No Title",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // ✅ Genre
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
        );
      },
    );
  }

  Widget _buildMovieActionButtons() {
    final currentMovie =
        (movies.isNotEmpty && _currentCarouselIndex < movies.length)
            ? movies[_currentCarouselIndex]
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (currentMovie != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SelectTheaterScreen(movie: currentMovie),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.local_activity, size: 16),
              label: const Text('Book Ticket', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (currentMovie != null) {
                  viewDetails(currentMovie);
                }
              },
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
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

        return AspectRatio(
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
        );
      },
    );
  }
}
