import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/share_service.dart';
import '../../services/storage_service.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class PdfSuccessScreen extends StatefulWidget {
  final File file;
  final int pageCount;

  const PdfSuccessScreen({
    super.key,
    required this.file,
    required this.pageCount,
  });

  @override
  State<PdfSuccessScreen> createState() => _PdfSuccessScreenState();
}

class _PdfSuccessScreenState extends State<PdfSuccessScreen> {
  final ShareService shareService = ShareService();

  final StorageService storageService = StorageService();

  bool isExporting = false;

  String get fileName {
    return widget.file.path.split(Platform.pathSeparator).last;
  }

  Future<void> _viewPdf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(file: widget.file),
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      await shareService.sharePdf(widget.file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
    }
  }

  Future<void> _exportPdf() async {
    if (isExporting) return;

    try {
      setState(() {
        isExporting = true;
      });

      final savedUri = await storageService.exportPdf(widget.file);

      if (!mounted) return;

      if (savedUri == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  void _backHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 46,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'PDF Created',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your PDF is ready to view, share or export.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 28),

              _FileInfoCard(fileName: fileName, pageCount: widget.pageCount),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _viewPdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('View PDF'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _sharePdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share PDF'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isExporting ? null : _exportPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(isExporting ? 'Exporting...' : 'Export PDF'),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: _backHome,
                child: const Text('Back to Home'),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileInfoCard extends StatelessWidget {
  final String fileName;
  final int pageCount;

  const _FileInfoCard({required this.fileName, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$pageCount page${pageCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
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
