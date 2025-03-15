import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tixtogo/models/movies.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/repositories/movie_repository.dart';

class AdminMovies extends StatefulWidget {
  final Map<String, dynamic>? movieToEdit;
  const AdminMovies({Key? key, this.movieToEdit}) : super(key: key);

  @override
  State<AdminMovies> createState() => _AdminMoviesState();
}

class _AdminMoviesState extends State<AdminMovies> {
  bool _isEditing = false;
  String? _movieId;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _castController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  String _status = 'Showing';

  XFile? _selectedImage; // Changed from File to XFile
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final supabase = Supabase.instance.client;
  final MovieRepository _movieRepository = MovieRepository();

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing movie
    if (widget.movieToEdit != null) {
      _isEditing = true;
      _loadMovieData();
    }
  }

  // Add this method to load existing movie data
  void _loadMovieData() {
    final movie = widget.movieToEdit!;

    // Store the movie ID for updating
    _movieId = movie['id'];

    // Fill the form controllers with existing data
    _titleController.text = movie['title'] ?? '';
    _yearController.text = movie['year'] ?? '';
    _ratingController.text = movie['rating']?.toString() ?? '';
    _durationController.text = movie['duration'] ?? '';
    _descriptionController.text = movie['description'] ?? '';
    _imageController.text = movie['image'] ?? '';
    _castController.text = movie['cast'] ?? '';
    _directorController.text = movie['director'] ?? '';
    _genreController.text = movie['genre'] ?? '';

    // Set status dropdown
    _status = movie['status'] ?? 'Showing';

    // Handle release date - direct date handling
    if (movie['release_date'] != null) {
      try {
        // Handle both string and DateTime types safely
        if (movie['release_date'] is String) {
          // Parse and reformat to ensure consistency
          final parsedDate = DateTime.parse(movie['release_date'] as String);
          _releaseDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(parsedDate);
        } else if (movie['release_date'] is DateTime) {
          // Format directly without UTC conversion
          _releaseDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(movie['release_date'] as DateTime);
        }
      } catch (e) {
        print('Error processing release date: $e');
        _releaseDateController.text = '';
      }
    } else {
      _releaseDateController.text = '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image; // Store XFile directly
          _imageController.text = 'Uploading...';
        });
        await _uploadImageToSupabase();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadImageToSupabase() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Start simulating progress
    _simulateUploadProgress();

    try {
      // Read image as bytes
      final Uint8List fileBytes = await _selectedImage!.readAsBytes();

      // Extract filename and extension
      final String fileName = _selectedImage!.name;
      final String fileExtension = fileName.split('.').last;

      // Generate unique filename
      final String randomString = _generateRandomString(8);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueFileName = '${timestamp}_$randomString.$fileExtension';

      // Upload bytes to Supabase using uploadBinary instead of upload
      await supabase.storage
          .from('movies')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final String publicUrl = supabase.storage
          .from('movies')
          .getPublicUrl(uniqueFileName);

      setState(() {
        _imageController.text = publicUrl;
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _imageController.text = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: ${e.toString()}')),
      );
    }
  }

  // Simulate upload progress since Supabase doesn't provide progress updates directly
  Future<void> _simulateUploadProgress() async {
    setState(() {
      _uploadProgress = 0.0;
    });

    while (_isUploading && _uploadProgress < 0.95) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _uploadProgress += 0.05;
        if (_uploadProgress > 0.95) _uploadProgress = 0.95;
      });

      if (!_isUploading) break;
    }
  }

  void _saveMovie() async {
    if (_formKey.currentState!.validate()) {
      // Check if image is uploaded
      if (_imageController.text.isEmpty ||
          _imageController.text == 'Uploading...') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for image to upload or select an image'),
          ),
        );
        return;
      }

      // Show loading indicator
      setState(() {
        _isUploading = true;
      });

      try {
        final movieData = Movies(
          title: _titleController.text,
          year: _yearController.text,
          rating: double.parse(_ratingController.text),
          duration: _durationController.text,
          description: _descriptionController.text,
          image: _imageController.text,
          cast: _castController.text,
          director: _directorController.text,
          genre: _genreController.text,
          status: _status,
          releaseDate: DateTime.parse(_releaseDateController.text),
        );

        if (_isEditing && _movieId != null) {
          // Update existing movie
          await _movieRepository.updateMovie(_movieId!, movieData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie updated successfully!')),
          );
        } else {
          // Add new movie
          await _movieRepository.addMovie(movieData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie added successfully!')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving movie: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Add Movie',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Movie Details',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Selector
                  _buildImageSelector(),

                  _buildTextField(_titleController, 'Title'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_yearController, 'Year')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _ratingController,
                          'Rating',
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(_durationController, 'Duration'),
                  _buildTextField(
                    _descriptionController,
                    'Description',
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_directorController, 'Director'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_genreController, 'Genre'),
                      ),
                    ],
                  ),
                  _buildTextField(_castController, 'Cast'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _releaseDateController,
                          'Release Date (YYYY-MM-DD)',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown()),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveMovie,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child:
                          _isUploading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                              : const Text(
                                'Save Movie',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movie Poster',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child:
                  _imageController.text.isNotEmpty &&
                          _imageController.text != 'Uploading...'
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _imageController.text,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                            ),
                            if (_isUploading)
                              Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _uploadProgress,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.amber,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                      : Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.amber,
                                size: 50,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to select movie poster',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          if (_isUploading)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _uploadProgress,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.amber,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
            ),
          ),
          if (_imageController.text.isNotEmpty &&
              !_isUploading &&
              _imageController.text != 'Uploading...')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image URL: ${_imageController.text}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amber),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade900,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          if (label == 'Rating' &&
              (double.tryParse(value) == null ||
                  double.parse(value) < 0 ||
                  double.parse(value) > 6)) {
            return 'Please enter a valid rating between 0-5';
          }
          if (label == 'Release Date (YYYY-MM-DD)') {
            try {
              DateTime.parse(value);
            } catch (e) {
              return 'Please enter a valid date format (YYYY-MM-DD)';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _status,
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.grey.shade900,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amber),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade900.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Showing', child: Text('Now Showing')),
          DropdownMenuItem(value: 'Coming Soon', child: Text('Upcoming Soon')),
          DropdownMenuItem(value: 'Done Showing', child: Text('Done Showing')),
        ],
        onChanged: (value) {
          setState(() {
            _status = value!;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _ratingController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _castController.dispose();
    _directorController.dispose();
    _genreController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }
}
