import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/models/theaters.dart';
import 'package:tixtogo/repositories/theater_repository.dart';

class AdminTheaters extends StatefulWidget {
  final Map<String, dynamic>? theaterToEdit;
  const AdminTheaters({Key? key, this.theaterToEdit}) : super(key: key);

  @override
  State<AdminTheaters> createState() => _AdminTheatersState();
}

class _AdminTheatersState extends State<AdminTheaters> {
  bool _isEditing = false;
  String? _theaterId;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _seatingCapacityController =
      TextEditingController();

  XFile? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final supabase = Supabase.instance.client;
  final TheaterRepository _theaterRepository = TheaterRepository();

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
    if (widget.theaterToEdit != null) {
      _isEditing = true;
      _loadTheaterData();
    }
  }

  void _loadTheaterData() {
    final theater = widget.theaterToEdit!;
    _theaterId = theater['id'];
    _nameController.text = theater['name'] ?? '';
    _distanceController.text = theater['distance'] ?? '';
    _imageController.text = theater['image'] ?? '';
    _locationController.text = theater['location'] ?? '';
    _seatingCapacityController.text =
        theater['seating_capacity']?.toString() ?? '';
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
          _selectedImage = image;
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

    _simulateUploadProgress();

    try {
      final Uint8List fileBytes = await _selectedImage!.readAsBytes();
      final String fileName = _selectedImage!.name;
      final String fileExtension = fileName.split('.').last;
      final String randomString = _generateRandomString(8);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueFileName = '${timestamp}_$randomString.$fileExtension';

      await supabase.storage
          .from('theaters')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = supabase.storage
          .from('theaters')
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

  void _saveTheater() async {
    if (_formKey.currentState!.validate()) {
      if (_imageController.text.isEmpty ||
          _imageController.text == 'Uploading...') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for image to upload or select an image'),
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        // Fixed the parameter name from seatingCapity to seatingCapacity
        final theaterData = Theater(
          name: _nameController.text,
          distance: _distanceController.text,
          image: _imageController.text,
          location: _locationController.text,
          seatingCapity:
              _seatingCapacityController.text, // Fixed parameter name
        );

        if (_isEditing && _theaterId != null) {
          await _theaterRepository.updateTheater(_theaterId!, theaterData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theater updated successfully!')),
          );
        } else {
          await _theaterRepository.addTheater(theaterData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theater added successfully!')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving theater: ${e.toString()}'),
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
        title: Text(
          _isEditing ? 'Edit Theater' : 'Add Theater',
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
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
                    'Theater Details',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageSelector(),
                  _buildTextField(_nameController, 'Theater Name'),
                  _buildTextField(_locationController, 'Location'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_distanceController, 'Distance'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _seatingCapacityController,
                          'Seating Capacity',
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveTheater,
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
                              : Text(
                                _isEditing ? 'Update Theater' : 'Save Theater',
                                style: const TextStyle(
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
            'Theater Image',
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
                                'Tap to select theater image',
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
          if (label == 'Seating Capacity' &&
              (int.tryParse(value) == null || int.parse(value) <= 0)) {
            return 'Please enter a valid seating capacity';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _distanceController.dispose();
    _imageController.dispose();
    _locationController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }
}
