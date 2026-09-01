import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<Directory> getPdfDirectory() async {
    final directory = await getApplicationDocumentsDirectory();

    final pdfDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}pdfs',
    );

    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    return pdfDirectory;
  }

  Future<List<File>> getPdfFiles() async {
    final directory = await getPdfDirectory();

    final entities = await directory.list().toList();

    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.pdf'))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files;
  }

  Future<File> renamePdf(File file, String newName) async {
    final directory = file.parent;

    var safeName = newName.trim();

    if (safeName.toLowerCase().endsWith('.pdf')) {
      safeName = safeName.substring(0, safeName.length - 4);
    }

    safeName = safeName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    if (safeName.isEmpty) {
      safeName = 'Document';
    }

    var newFile = File(
      '${directory.path}'
      '${Platform.pathSeparator}'
      '$safeName.pdf',
    );

    if (newFile.path == file.path) {
      return file;
    }

    var counter = 1;

    while (await newFile.exists()) {
      newFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '$safeName ($counter).pdf',
      );

      counter++;
    }

    return file.rename(newFile.path);
  }

  Future<void> deletePdf(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Uri?> exportPdf(File file) async {
    if (!await file.exists()) {
      throw Exception('PDF file does not exist.');
    }

    final fileName = file.path.split(Platform.pathSeparator).last;

    final bytes = await file.readAsBytes();

    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Save PDF',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    return savedUri;
  }
}
