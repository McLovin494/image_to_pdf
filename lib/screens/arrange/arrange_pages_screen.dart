import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/image_picker_service.dart';
import '../create_pdf/pdf_settings_screen.dart';

class ArrangePagesScreen extends StatefulWidget {
  final List<XFile> images;

  const ArrangePagesScreen({super.key, required this.images});

  @override
  State<ArrangePagesScreen> createState() => _ArrangePagesScreenState();
}

class _ArrangePagesScreenState extends State<ArrangePagesScreen> {
  late List<XFile> images;

  final ImagePickerService imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();

    images = List<XFile>.from(widget.images);
  }

  Future<void> _cropImage(int index) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: images[index].path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Page',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Page', aspectRatioLockEnabled: false),
        ],
      );

      if (croppedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        images[index] = XFile(croppedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to crop image: $e')));
    }
  }

  Future<void> _rotateImage(int index) async {
    try {
      final originalFile = File(images[index].path);

      final bytes = await originalFile.readAsBytes();

      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('Could not decode image');
      }

      final rotatedImage = img.copyRotate(decodedImage, angle: 90);

      final tempDirectory = await getTemporaryDirectory();

      final rotatedFile = File(
        '${tempDirectory.path}'
        '${Platform.pathSeparator}'
        'rotated_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );

      await rotatedFile.writeAsBytes(
        img.encodeJpg(rotatedImage, quality: 95),
        flush: true,
      );

      if (!mounted) return;

      setState(() {
        images[index] = XFile(rotatedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to rotate image: $e')));
    }
  }

  Future<void> _showAddMoreOptions() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add more pages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose where you want to add pages from.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                _AddSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  subtitle: 'Select multiple images',
                  onTap: () {
                    Navigator.pop(sheetContext, 'gallery');
                  },
                ),

                const SizedBox(height: 10),

                _AddSourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  subtitle: 'Capture another page',
                  onTap: () {
                    Navigator.pop(sheetContext, 'camera');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (source == 'gallery') {
      await _addFromGallery();
    }

    if (source == 'camera') {
      await _addFromCamera();
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final newImages = await imagePickerService.pickMultipleImages();

      if (!mounted || newImages.isEmpty) {
        return;
      }

      setState(() {
        images.addAll(newImages);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add images: $e')));
    }
  }

  Future<void> _addFromCamera() async {
    try {
      final image = await imagePickerService.captureImage();

      if (!mounted || image == null) {
        return;
      }

      setState(() {
        images.add(image);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final image = images.removeAt(oldIndex);

      images.insert(newIndex, image);
    });
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  void _continueToSettings() {
    if (images.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfSettingsScreen(images: images),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Arrange Pages',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddMoreOptions,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(imageCount: images.length),

            Expanded(
              child: images.isEmpty
                  ? const _EmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: images.length,
                      onReorder: _reorderImages,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final image = images[index];

                        return _PageItem(
                          key: ValueKey(image.path),
                          image: image,
                          index: index,
                          onCrop: () {
                            _cropImage(index);
                          },
                          onRotate: () {
                            _rotateImage(index);
                          },
                          onRemove: () {
                            _removeImage(index);
                          },
                        );
                      },
                    ),
            ),

            if (images.isNotEmpty)
              _BottomAction(
                imageCount: images.length,
                onContinue: _continueToSettings,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int imageCount;

  const _Header({required this.imageCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrange your pages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Crop, rotate or drag pages into the order you want.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$imageCount pages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageItem extends StatelessWidget {
  final XFile image;
  final int index;

  final VoidCallback onCrop;
  final VoidCallback onRotate;
  final VoidCallback onRemove;

  const _PageItem({
    super.key,
    required this.image,
    required this.index,
    required this.onCrop,
    required this.onRotate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(image.path),
              width: 72,
              height: 92,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Image page',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onCrop,
            tooltip: 'Crop',
            icon: const Icon(Icons.crop_rounded, size: 21),
            color: AppColors.textSecondary,
          ),

          IconButton(
            onPressed: onRotate,
            tooltip: 'Rotate',
            icon: const Icon(Icons.rotate_right_rounded, size: 21),
            color: AppColors.textSecondary,
          ),

          IconButton(
            onPressed: onRemove,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
            color: AppColors.textSecondary,
          ),

          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final int imageCount;
  final VoidCallback onContinue;

  const _BottomAction({required this.imageCount, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onContinue,
            child: Text('Continue with $imageCount pages'),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),

            SizedBox(height: 14),

            Text(
              'No images left',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 6),

            Text(
              'Use Add to select more images.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
