import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _pageSizeKey = 'default_page_size';
  static const String _marginKey = 'default_margin';
  static const String _qualityKey = 'default_image_quality';

  static const String defaultPageSize = 'A4';
  static const String defaultMargin = 'Small';
  static const double defaultImageQuality = 85;

  Future<void> savePageSize(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pageSizeKey, value);
  }

  Future<String> getPageSize() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_pageSizeKey) ?? defaultPageSize;
  }

  Future<void> saveMargin(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_marginKey, value);
  }

  Future<String> getMargin() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_marginKey) ?? defaultMargin;
  }

  Future<void> saveImageQuality(double value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_qualityKey, value);
  }

  Future<double> getImageQuality() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getDouble(_qualityKey) ?? defaultImageQuality;
  }
}
