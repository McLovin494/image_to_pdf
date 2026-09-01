import 'package:flutter/material.dart';
import 'package:image_to_pdf/core/theme/app_theme.dart';
import 'package:image_to_pdf/screens/home/home_screen.dart';

class ImageToPdfApp extends StatelessWidget {
  const ImageToPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Image to pdf",
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
