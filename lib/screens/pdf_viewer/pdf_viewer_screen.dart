import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_to_pdf/services/share_service.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/theme/app_colors.dart';

class PdfViewerScreen extends StatelessWidget {
  final File file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final shareService = ShareService();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await shareService.sharePdf(file);
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: PdfViewer.file(file.path),
      ),
    );
  }
}
