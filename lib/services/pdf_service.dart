import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../screens/create_pdf/pdf_settings_screen.dart';

class PdfService {
  Future<File> _getUniqueFile({
    required Directory directory,
    required String fileName,
  }) async {
    var file = File(
      '${directory.path}'
      '${Platform.pathSeparator}'
      '$fileName.pdf',
    );

    if (!await file.exists()) {
      return file;
    }

    var counter = 1;

    while (true) {
      file = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '$fileName ($counter).pdf',
      );

      if (!await file.exists()) {
        return file;
      }

      counter++;
    }
  }

  Future<File> createPdf({
    required List<XFile> images,
    required String fileName,
    required PdfPageSize pageSize,
    required PdfOrientation orientation,
    required PdfMargin margin,
    required double imageQuality,
  }) async {
    final pdf = pw.Document();

    for (final image in images) {
      final originalBytes = await File(image.path).readAsBytes();

      var decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      const maxDimension = 2400;

      if (decodedImage.width > maxDimension ||
          decodedImage.height > maxDimension) {
        if (decodedImage.width >= decodedImage.height) {
          decodedImage = img.copyResize(
            decodedImage,
            width: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        } else {
          decodedImage = img.copyResize(
            decodedImage,
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      final quality = imageQuality.round().clamp(10, 100);

      final compressedBytes = img.encodeJpg(decodedImage, quality: quality);

      final pdfImage = pw.MemoryImage(compressedBytes);

      final format = _getPageFormat(
        pageSize: pageSize,
        orientation: orientation,
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );

      final pageMargin = pageSize == PdfPageSize.fitImage
          ? pw.EdgeInsets.zero
          : _getMargin(margin);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pageMargin,
          build: (context) {
            return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
          },
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();

    final pdfDirectory = Directory(
      '${directory.path}'
      '${Platform.pathSeparator}'
      'pdfs',
    );

    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    final safeFileName = _sanitizeFileName(fileName);

    final file = await _getUniqueFile(
      directory: pdfDirectory,
      fileName: safeFileName,
    );

    await file.writeAsBytes(await pdf.save(), flush: true);

    return file;
  }

  PdfPageFormat _getPageFormat({
    required PdfPageSize pageSize,
    required PdfOrientation orientation,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (pageSize == PdfPageSize.fitImage) {
      double width = imageWidth.toDouble();

      double height = imageHeight.toDouble();

      const maxPageDimension = 842.0;

      final largestDimension = width > height ? width : height;

      if (largestDimension > maxPageDimension) {
        final scale = maxPageDimension / largestDimension;

        width *= scale;
        height *= scale;
      }

      return PdfPageFormat(width, height, marginAll: 0);
    }

    PdfPageFormat format;

    switch (pageSize) {
      case PdfPageSize.a4:
        format = PdfPageFormat.a4;
        break;

      case PdfPageSize.letter:
        format = PdfPageFormat.letter;
        break;

      case PdfPageSize.fitImage:
        throw StateError('Fit Image should have been handled earlier.');
    }

    if (orientation == PdfOrientation.landscape) {
      return format.landscape;
    }

    return format.portrait;
  }

  pw.EdgeInsets _getMargin(PdfMargin margin) {
    switch (margin) {
      case PdfMargin.none:
        return pw.EdgeInsets.zero;

      case PdfMargin.small:
        return const pw.EdgeInsets.all(12);

      case PdfMargin.medium:
        return const pw.EdgeInsets.all(24);

      case PdfMargin.large:
        return const pw.EdgeInsets.all(40);
    }
  }

  String _sanitizeFileName(String fileName) {
    var result = fileName.trim();

    if (result.toLowerCase().endsWith('.pdf')) {
      result = result.substring(0, result.length - 4);
    }

    result = result.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    if (result.isEmpty) {
      result = 'Document';
    }

    return result;
  }
}
