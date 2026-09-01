import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_to_pdf/screens/camera/camera_capture_screen.dart';
import 'package:image_to_pdf/screens/gallery/gallery_screen.dart';
import 'package:image_to_pdf/screens/library/my_pdfs_screen.dart';
import 'package:image_to_pdf/screens/setttings/settings_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/storage_service.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

import '../tools/tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();

  List<File> _recentPdfs = [];

  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentPdfs();
  }

  Future<void> _loadRecentPdfs() async {
    try {
      final files = await _storageService.getPdfFiles();

      if (!mounted) return;

      setState(() {
        _recentPdfs = files.take(3).toList();
        _isLoadingRecent = false;
      });
    } catch (e) {
      debugPrint('Failed to load recent PDFs: $e');

      if (!mounted) return;

      setState(() {
        _recentPdfs = [];
        _isLoadingRecent = false;
      });
    }
  }

  Future<void> _openCameraCapture() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );

    if (!mounted) return;

    await _loadRecentPdfs();
  }

  Future<void> _openGallery() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GalleryScreen()),
    );

    if (!mounted) return;

    await _loadRecentPdfs();
  }

  Future<void> _openMyPdfs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyPdfsScreen()),
    );

    if (!mounted) return;

    await _loadRecentPdfs();
  }

  Future<void> _openTools() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ToolsScreen()),
    );

    if (!mounted) return;

    await _loadRecentPdfs();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _openPdf(File file) async {
    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This PDF no longer exists.')),
      );

      await _loadRecentPdfs();

      return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
    );

    if (!mounted) return;

    await _loadRecentPdfs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentPdfs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hi 👋', style: AppTextStyles.heading),
                        const SizedBox(height: 6),
                        Text(
                          'Convert your images to PDF\nquickly and easily.',
                          style: AppTextStyles.bodySecondary.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _openSettings,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.settings_outlined,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _PrimaryFeatureCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'Convert to PDF',
                  subtitle: 'Capture new images',
                  onTap: _openCameraCapture,
                ),

                const SizedBox(height: 14),

                _FeatureCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select images from gallery',
                  onTap: _openGallery,
                ),

                const SizedBox(height: 14),

                _FeatureCard(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'My PDFs',
                  subtitle: 'View and manage your PDFs',
                  onTap: _openMyPdfs,
                ),

                const SizedBox(height: 30),

                _buildRecentFilesSection(),

                const SizedBox(height: 32),

                Center(
                  child: Text(
                    'HOW IT WORKS',
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const _HowItWorks(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        onCameraTap: _openCameraCapture,
        onMyPdfsTap: _openMyPdfs,
        onToolsTap: _openTools,
        onSettingsTap: _openSettings,
      ),
    );
  }

  Widget _buildRecentFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent PDFs',
                style: AppTextStyles.title.copyWith(fontSize: 17),
              ),
            ),
            if (_recentPdfs.isNotEmpty)
              TextButton(
                onPressed: _openMyPdfs,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (_isLoadingRecent)
          const _RecentLoadingCard()
        else if (_recentPdfs.isEmpty)
          const _RecentEmptyCard()
        else
          ...List.generate(_recentPdfs.length, (index) {
            final file = _recentPdfs[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _recentPdfs.length - 1 ? 0 : 10,
              ),
              child: _RecentPdfCard(
                file: file,
                onTap: () {
                  _openPdf(file);
                },
              ),
            );
          }),
      ],
    );
  }
}

class _RecentPdfCard extends StatelessWidget {
  final File file;
  final VoidCallback onTap;

  const _RecentPdfCard({required this.file, required this.onTap});

  String get _fileName {
    return file.path.split(Platform.pathSeparator).last;
  }

  String get _fileSize {
    try {
      final bytes = file.lengthSync();

      if (bytes < 1024) {
        return '$bytes B';
      }

      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }

      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  String get _modifiedDate {
    try {
      final date = file.lastModifiedSync();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        if (_fileSize.isNotEmpty)
                          Text(
                            _fileSize,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 11,
                            ),
                          ),

                        if (_fileSize.isNotEmpty && _modifiedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                        if (_modifiedDate.isNotEmpty)
                          Text(
                            _modifiedDate,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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

class _RecentEmptyCard extends StatelessWidget {
  const _RecentEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'No PDFs yet',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          const Text(
            'Your recently created PDFs will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _RecentLoadingCard extends StatelessWidget {
  const _RecentLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _PrimaryFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 104,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.title.copyWith(
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.title.copyWith(fontSize: 15),
                    ),

                    const SizedBox(height: 4),

                    Text(subtitle, style: AppTextStyles.bodySecondary),
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

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StepItem(
            number: '1',
            icon: Icons.add_photo_alternate_outlined,
            label: 'Add Images',
          ),
        ),
        _Arrow(),
        Expanded(
          child: _StepItem(
            number: '2',
            icon: Icons.drag_indicator_rounded,
            label: 'Arrange',
          ),
        ),
        _Arrow(),
        Expanded(
          child: _StepItem(
            number: '3',
            icon: Icons.picture_as_pdf_outlined,
            label: 'Save PDF',
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final IconData icon;
  final String label;

  const _StepItem({
    required this.number,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: AppColors.border,
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onMyPdfsTap;
  final VoidCallback onToolsTap;
  final VoidCallback onSettingsTap;

  const _BottomNavigation({
    required this.onCameraTap,
    required this.onMyPdfsTap,
    required this.onToolsTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
              ),

              _NavItem(
                icon: Icons.picture_as_pdf_outlined,
                label: 'My PDFs',
                onTap: onMyPdfsTap,
              ),

              _CameraNavButton(onTap: onCameraTap),

              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Tools',
                onTap: onToolsTap,
              ),

              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: onSettingsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),

            const SizedBox(height: 4),

            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
