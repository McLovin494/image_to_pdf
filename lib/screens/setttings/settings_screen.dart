import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  String defaultPageSize = SettingsService.defaultPageSize;
  String defaultMargin = SettingsService.defaultMargin;
  double defaultQuality = SettingsService.defaultImageQuality;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final pageSize = await _settingsService.getPageSize();
      final margin = await _settingsService.getMargin();
      final quality = await _settingsService.getImageQuality();

      if (!mounted) return;

      setState(() {
        defaultPageSize = pageSize;
        defaultMargin = margin;
        defaultQuality = quality;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load settings: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _changePageSize(String? value) async {
    if (value == null) return;

    setState(() {
      defaultPageSize = value;
    });

    try {
      await _settingsService.savePageSize(value);
    } catch (e) {
      debugPrint('Failed to save page size: $e');
    }
  }

  Future<void> _changeMargin(String? value) async {
    if (value == null) return;

    setState(() {
      defaultMargin = value;
    });

    try {
      await _settingsService.saveMargin(value);
    } catch (e) {
      debugPrint('Failed to save margin: $e');
    }
  }

  Future<void> _changeImageQuality(double value) async {
    setState(() {
      defaultQuality = value;
    });
  }

  Future<void> _saveImageQuality(double value) async {
    try {
      await _settingsService.saveImageQuality(value);
    } catch (e) {
      debugPrint('Failed to save image quality: $e');
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Image to PDF',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026',
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy'),
          content: const Text(
            'Your images and PDFs are processed locally on your device. '
            'The app does not upload your documents to a server.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Defaults',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  const SizedBox(height: 12),

                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingDropdown(
                          icon: Icons.description_outlined,
                          title: 'Page Size',
                          value: defaultPageSize,
                          items: const ['A4', 'Letter', 'Fit Image'],
                          onChanged: _changePageSize,
                        ),

                        const _SettingsDivider(),

                        _SettingDropdown(
                          icon: Icons.border_outer_rounded,
                          title: 'Margin',
                          value: defaultMargin,
                          items: const ['None', 'Small', 'Medium', 'Large'],
                          onChanged: _changeMargin,
                        ),

                        const _SettingsDivider(),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SettingIcon(
                                icon: Icons.high_quality_outlined,
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Image Quality',
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${defaultQuality.round()}%',
                                          style: AppTextStyles.bodySecondary
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    const Text(
                                      'Default quality for generated PDFs',
                                      style: AppTextStyles.bodySecondary,
                                    ),

                                    Slider(
                                      value: defaultQuality,
                                      min: 40,
                                      max: 100,
                                      divisions: 6,
                                      activeColor: AppColors.primary,
                                      onChanged: _changeImageQuality,
                                      onChangeEnd: _saveImageQuality,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'App',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  const SizedBox(height: 12),

                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy',
                          subtitle: 'How your documents are handled',
                          onTap: _showPrivacy,
                        ),

                        const _SettingsDivider(),

                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'Image to PDF',
                          onTap: _showAbout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SettingDropdown extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SettingDropdown({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _SettingIcon(icon: icon),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: AppTextStyles.body),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _SettingIcon(icon: icon),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

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
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;

  const _SettingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}
