import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';

class PhotoManager extends StatefulWidget {
  final List<String> initialPhotos;
  final String? plantId;
  final Function(List<String>) onPhotosChanged;

  const PhotoManager({
    super.key,
    required this.initialPhotos,
    this.plantId,
    required this.onPhotosChanged,
  });

  @override
  State<PhotoManager> createState() => _PhotoManagerState();
}

class _PhotoManagerState extends State<PhotoManager> {
  final ImagePicker _picker = ImagePicker();
  late List<String> _photos;
  final List<File> _pendingUploads = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _showAddPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose Multiple'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadPhoto(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      for (final image in images) {
        await _uploadPhoto(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto(File file) async {
    if (widget.plantId == null) {
      // If no plant ID yet (new plant), just add to pending uploads
      setState(() {
        _pendingUploads.add(file);
      });
      return;
    }

    setState(() => _isUploading = true);

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.uploadFile(
        '/owner/plant/${widget.plantId}/photos',
        file,
        'photo',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        final photoUrl = data['url'] ?? data['photoUrl'];
        if (photoUrl != null) {
          setState(() {
            _photos.add(photoUrl);
          });
          widget.onPhotosChanged(_photos);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (widget.plantId != null) {
      try {
        final apiClient = RepositoryProvider.of<ApiClient>(context);
        final photoUrl = _photos[index];
        await apiClient.delete(
          '/owner/plant/${widget.plantId}/photos',
          data: {'photoUrl': photoUrl},
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete photo: $e')),
          );
        }
        return;
      }
    }

    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _deletePendingPhoto(int index) {
    setState(() {
      _pendingUploads.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = _photos.length + _pendingUploads.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${totalPhotos}/10)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              if (totalPhotos < 10)
                GestureDetector(
                  onTap: _showAddPhotoOptions,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[400]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              // Existing photos
              ..._photos.asMap().entries.map((entry) => _PhotoItem(
                    key: ValueKey('photo_${entry.key}'),
                    imageUrl: entry.value,
                    onDelete: () => _deletePhoto(entry.key),
                  )),
              // Pending uploads
              ..._pendingUploads.asMap().entries.map((entry) => _LocalPhotoItem(
                    key: ValueKey('pending_${entry.key}'),
                    file: entry.value,
                    onDelete: () => _deletePendingPhoto(entry.key),
                  )),
            ],
          ),
        ),
        if (_pendingUploads.isNotEmpty && widget.plantId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Photos will be uploaded when you save the plant',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onDelete;

  const _PhotoItem({
    super.key,
    required this.imageUrl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalPhotoItem extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _LocalPhotoItem({
    super.key,
    required this.file,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
