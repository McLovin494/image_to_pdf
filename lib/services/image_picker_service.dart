import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickMultipleImages() async {
    return await _picker.pickMultiImage();
  }

  Future<XFile?> captureImage() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
  }
}
