import 'dart:io';

import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> sharePdf(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'PDF Document'),
    );
  }
}
