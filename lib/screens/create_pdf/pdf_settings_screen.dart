import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_pdf/screens/create_pdf/pdf_success_screen.dart';
import 'package:image_to_pdf/services/pdf_service.dart';

import '../../core/theme/app_colors.dart';
import '../../services/settings_service.dart';

enum PdfPageSize { a4, letter, fitImage }

enum PdfOrientation { portrait, landscape }

enum PdfMargin { none, small, medium, large }

class PdfSettingsScreen extends StatefulWidget {
  final List<XFile> images;

  const PdfSettingsScreen({super.key, required this.images});

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  final TextEditingController fileNameController = TextEditingController(
    text: 'My Document',
  );

  final PdfService pdfService = PdfService();
  final SettingsService settingsService = SettingsService();

  bool isCreating = false;
  bool isLoadingDefaults = true;

  PdfPageSize pageSize = PdfPageSize.a4;
  PdfOrientation orientation = PdfOrientation.portrait;
  PdfMargin margin = PdfMargin.small;
  double imageQuality = 85;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final savedPageSize = await settingsService.getPageSize();
      final savedMargin = await settingsService.getMargin();
      final savedQuality = await settingsService.getImageQuality();

      if (!mounted) return;

      setState(() {
        pageSize = _mapPageSize(savedPageSize);
        margin = _mapMargin(savedMargin);
        imageQuality = savedQuality.clamp(40, 100).toDouble();
        isLoadingDefaults = false;
      });
    } catch (e) {
      debugPrint('Failed to load PDF defaults: $e');

      if (!mounted) return;

      setState(() {
        isLoadingDefaults = false;
      });
    }
  }

  PdfPageSize _mapPageSize(String value) {
    switch (value) {
      case 'Letter':
        return PdfPageSize.letter;

      case 'Fit Image':
        return PdfPageSize.fitImage;

      case 'A4':
      default:
        return PdfPageSize.a4;
    }
  }

  PdfMargin _mapMargin(String value) {
    switch (value) {
      case 'None':
        return PdfMargin.none;

      case 'Medium':
        return PdfMargin.medium;

      case 'Large':
        return PdfMargin.large;

      case 'Small':
      default:
        return PdfMargin.small;
    }
  }

  @override
  void dispose() {
    fileNameController.dispose();
    super.dispose();
  }

  Future<void> _createPdf() async {
    final fileName = fileNameController.text.trim();

    if (fileName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a file name')));

      return;
    }

    try {
      setState(() {
        isCreating = true;
      });

      final file = await pdfService.createPdf(
        images: widget.images,
        fileName: fileName,
        pageSize: pageSize,
        orientation: orientation,
        margin: margin,
        imageQuality: imageQuality,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PdfSuccessScreen(file: file, pageCount: widget.images.length),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to create PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFitImage = pageSize == PdfPageSize.fitImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF Settings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: isLoadingDefaults
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DocumentSummary(pageCount: widget.images.length),

                          const SizedBox(height: 28),

                          const _SectionTitle(title: 'FILE NAME'),

                          const SizedBox(height: 10),

                          TextField(
                            controller: fileNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter PDF name',
                              prefixIcon: Icon(Icons.picture_as_pdf_outlined),
                              suffixText: '.pdf',
                            ),
                          ),

                          const SizedBox(height: 28),

                          const _SectionTitle(title: 'PAGE SIZE'),

                          const SizedBox(height: 10),

                          _OptionCard<PdfPageSize>(
                            value: pageSize,
                            options: const [
                              _Option(
                                value: PdfPageSize.a4,
                                title: 'A4',
                                subtitle: '210 × 297 mm',
                              ),
                              _Option(
                                value: PdfPageSize.letter,
                                title: 'Letter',
                                subtitle: '8.5 × 11 in',
                              ),
                              _Option(
                                value: PdfPageSize.fitImage,
                                title: 'Fit to image',
                                subtitle: 'Match each image size',
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                pageSize = value;
                              });
                            },
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle(title: 'ORIENTATION'),

                              if (isFitImage)
                                const Text(
                                  'Automatic',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _SelectableTile(
                                  icon: Icons.crop_portrait_rounded,
                                  title: 'Portrait',
                                  selected:
                                      !isFitImage &&
                                      orientation == PdfOrientation.portrait,
                                  enabled: !isFitImage,
                                  onTap: isFitImage
                                      ? null
                                      : () {
                                          setState(() {
                                            orientation =
                                                PdfOrientation.portrait;
                                          });
                                        },
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: _SelectableTile(
                                  icon: Icons.crop_landscape_rounded,
                                  title: 'Landscape',
                                  selected:
                                      !isFitImage &&
                                      orientation == PdfOrientation.landscape,
                                  enabled: !isFitImage,
                                  onTap: isFitImage
                                      ? null
                                      : () {
                                          setState(() {
                                            orientation =
                                                PdfOrientation.landscape;
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),

                          if (isFitImage) ...[
                            const SizedBox(height: 10),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),

                                  SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      'Orientation is determined by each image when using Fit to image.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          const _SectionTitle(title: 'PAGE MARGIN'),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MarginChip(
                                label: 'None',
                                selected: margin == PdfMargin.none,
                                onTap: () {
                                  setState(() {
                                    margin = PdfMargin.none;
                                  });
                                },
                              ),

                              _MarginChip(
                                label: 'Small',
                                selected: margin == PdfMargin.small,
                                onTap: () {
                                  setState(() {
                                    margin = PdfMargin.small;
                                  });
                                },
                              ),

                              _MarginChip(
                                label: 'Medium',
                                selected: margin == PdfMargin.medium,
                                onTap: () {
                                  setState(() {
                                    margin = PdfMargin.medium;
                                  });
                                },
                              ),

                              _MarginChip(
                                label: 'Large',
                                selected: margin == PdfMargin.large,
                                onTap: () {
                                  setState(() {
                                    margin = PdfMargin.large;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle(title: 'IMAGE QUALITY'),

                              Text(
                                '${imageQuality.round()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          Slider(
                            value: imageQuality,
                            min: 40,
                            max: 100,
                            divisions: 6,
                            onChanged: (value) {
                              setState(() {
                                imageQuality = value;
                              });
                            },
                          ),

                          const Text(
                            'Higher quality produces a larger PDF file.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _BottomCreateButton(
                    pageCount: widget.images.length,
                    isLoading: isCreating,
                    onPressed: isCreating ? null : _createPdf,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DocumentSummary extends StatelessWidget {
  final int pageCount;

  const _DocumentSummary({required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to create',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$pageCount images will become $pageCount PDF pages',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final String title;
  final String subtitle;

  const _Option({
    required this.value,
    required this.title,
    required this.subtitle,
  });
}

class _OptionCard<T> extends StatelessWidget {
  final T value;
  final List<_Option<T>> options;
  final ValueChanged<T> onChanged;

  const _OptionCard({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: options.map((option) {
              return RadioListTile<T>(
                value: option.value,
                groupValue: value,
                activeColor: AppColors.primary,
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
                title: Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  option.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _SelectableTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 94,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarginChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MarginChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onTap();
      },
    );
  }
}

class _BottomCreateButton extends StatelessWidget {
  final int pageCount;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _BottomCreateButton({
    required this.pageCount,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              isLoading ? 'Creating PDF...' : 'Create PDF • $pageCount pages',
            ),
          ),
        ),
      ),
    );
  }
}
