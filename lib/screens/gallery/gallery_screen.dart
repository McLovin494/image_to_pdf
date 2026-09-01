import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_pdf/screens/arrange/arrange_pages_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../services/image_picker_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();

  List<XFile> selectedImages = [];

  bool isLoading = false;

  Future<void> _pickImages() async {
    try {
      setState(() {
        isLoading = true;
      });

      final images = await _imagePickerService.pickMultipleImages();

      if (!mounted) return;

      setState(() {
        selectedImages = images;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not select images: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Images',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (selectedImages.isNotEmpty)
            TextButton(
              onPressed: () {
                // Arrange screen comes next.
              },
              child: const Text('Next'),
            ),
        ],
      ),
      body: selectedImages.isEmpty
          ? _buildEmptyState()
          : _buildSelectedImages(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Choose your images',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Select one or more images from your gallery to create a PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _pickImages,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  isLoading ? 'Opening Gallery...' : 'Choose from Gallery',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImages() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedImages.length} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add more'),
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: selectedImages.length,
            itemBuilder: (context, index) {
              final image = selectedImages[index];

              return _SelectedImageCard(
                image: image,
                number: index + 1,
                onRemove: () {
                  _removeImage(index);
                },
              );
            },
          ),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArrangePagesScreen(images: selectedImages),
                    ),
                  );
                },
                child: Text('Continue with ${selectedImages.length} images'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedImageCard extends StatelessWidget {
  final XFile image;
  final int number;
  final VoidCallback onRemove;

  const _SelectedImageCard({
    required this.image,
    required this.number,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),

        Positioned(
          top: 6,
          left: 6,
          child: Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
