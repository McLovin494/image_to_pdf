import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/share_service.dart';
import '../../services/storage_service.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class MyPdfsScreen extends StatefulWidget {
  const MyPdfsScreen({super.key});

  @override
  State<MyPdfsScreen> createState() => _MyPdfsScreenState();
}

class _MyPdfsScreenState extends State<MyPdfsScreen> {
  final StorageService storageService = StorageService();

  final ShareService shareService = ShareService();

  List<File> pdfFiles = [];

  bool isLoading = true;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();

    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    try {
      final files = await storageService.getPdfFiles();

      if (!mounted) return;

      setState(() {
        pdfFiles = files;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load PDFs: $e')));
    }
  }

  Future<void> _openPdf(File file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
    );

    if (!mounted) return;

    await _loadPdfs();
  }

  Future<void> _sharePdf(File file) async {
    try {
      await shareService.sharePdf(file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
    }
  }

  Future<void> _exportPdf(File file) async {
    if (isExporting) return;

    try {
      setState(() {
        isExporting = true;
      });

      final savedUri = await storageService.exportPdf(file);

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

  Future<void> _renamePdf(File file) async {
    final currentName = _getFileName(file).replaceAll('.pdf', '');

    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename PDF'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'PDF name',
              suffixText: '.pdf',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });

      return;
    }

    try {
      await storageService.renamePdf(file, newName);

      if (!mounted) return;

      await _loadPdfs();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to rename PDF: $e')));
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }
  }

  Future<void> _deletePdf(File file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete PDF?'),
          content: Text('Delete ${_getFileName(file)} permanently?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await storageService.deletePdf(file);

      if (!mounted) return;

      await _loadPdfs();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PDF deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete PDF: $e')));
    }
  }

  String _getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;

      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb = bytes / (1024 * 1024);

    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My PDFs',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPdfs,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pdfFiles.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: pdfFiles.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final file = pdfFiles[index];

                  return _PdfCard(
                    fileName: _getFileName(file),
                    fileSize: _formatFileSize(file.lengthSync()),
                    date: _formatDate(file.lastModifiedSync()),
                    onTap: () {
                      _openPdf(file);
                    },
                    onShare: () {
                      _sharePdf(file);
                    },
                    onExport: () {
                      _exportPdf(file);
                    },
                    onRename: () {
                      _renamePdf(file);
                    },
                    onDelete: () {
                      _deletePdf(file);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final String date;

  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PdfCard({
    required this.fileName,
    required this.fileSize,
    required this.date,
    required this.onTap,
    required this.onShare,
    required this.onExport,
    required this.onRename,
    required this.onDelete,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primary,
                  size: 26,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$fileSize • $date',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      onShare();
                      break;

                    case 'export':
                      onExport();
                      break;

                    case 'rename':
                      onRename();
                      break;

                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Share'),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Export'),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Rename'),
                        ],
                      ),
                    ),

                    PopupMenuDivider(),

                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),

        Icon(Icons.picture_as_pdf_outlined, size: 70, color: AppColors.primary),

        SizedBox(height: 20),

        Text(
          'No PDFs yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 8),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'PDFs you create will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
