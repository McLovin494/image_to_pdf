import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../arrange/arrange_pages_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  List<CameraDescription> _cameras = [];

  final List<XFile> capturedImages = [];

  bool isInitializing = true;
  bool isCapturing = false;

  String? errorMessage;

  FlashMode flashMode = FlashMode.off;

  int selectedCameraIndex = 0;

  // Tap-to-focus indicator.
  Offset? focusPoint;
  bool showFocusIndicator = false;

  int _focusRequestId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(cameraIndex: selectedCameraIndex);
    }
  }

  Future<void> _focusCamera(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final localPosition = details.localPosition;

    final x = localPosition.dx / constraints.maxWidth;

    final y = localPosition.dy / constraints.maxHeight;

    final normalizedPoint = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

    final requestId = ++_focusRequestId;

    if (mounted) {
      setState(() {
        focusPoint = localPosition;
        showFocusIndicator = true;
      });
    }

    try {
      await controller.setFocusPoint(normalizedPoint);

      await controller.setExposurePoint(normalizedPoint);
    } on CameraException catch (e) {
      debugPrint('Focus failed: ${e.description ?? e.code}');
    }

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    // Prevent an older tap from hiding
    // a newer focus indicator.
    if (requestId != _focusRequestId) {
      return;
    }

    setState(() {
      showFocusIndicator = false;
    });
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    try {
      if (mounted) {
        setState(() {
          isInitializing = true;
          errorMessage = null;
        });
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera available on this device.');
      }

      if (cameraIndex < 0 || cameraIndex >= _cameras.length) {
        cameraIndex = 0;
      }

      selectedCameraIndex = cameraIndex;

      final oldController = _controller;

      _controller = null;

      if (oldController != null) {
        await oldController.dispose();
      }

      final controller = CameraController(
        _cameras[selectedCameraIndex],
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );

      _controller = controller;

      await controller.initialize();

      try {
        await controller.setFlashMode(flashMode);
      } on CameraException {
        // Some cameras/devices may not support
        // the requested flash mode.
        flashMode = FlashMode.off;
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        isInitializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        isInitializing = false;
        errorMessage = _getCameraErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isInitializing = false;
        errorMessage = 'Failed to start camera: $e';
      });
    }
  }

  String _getCameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Camera permission was denied. Please allow camera access.';

      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access is disabled. Enable it from device settings.';

      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';

      default:
        return 'Camera error: ${error.description ?? error.code}';
    }
  }

  Future<void> _captureImage() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || isCapturing) {
      return;
    }

    try {
      setState(() {
        isCapturing = true;
      });

      final image = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        capturedImages.add(image);
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: ${e.description ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final newMode = flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;

      await controller.setFlashMode(newMode);

      if (!mounted) return;

      setState(() {
        flashMode = newMode;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flash unavailable: ${e.description ?? e.code}'),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || isInitializing || isCapturing) {
      return;
    }

    final nextIndex = (selectedCameraIndex + 1) % _cameras.length;

    await _initializeCamera(cameraIndex: nextIndex);
  }

  void _removeImage(int index) {
    if (index < 0 || index >= capturedImages.length) {
      return;
    }

    setState(() {
      capturedImages.removeAt(index);
    });
  }

  void _continue() {
    if (capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture at least one page')),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArrangePagesScreen(images: List<XFile>.from(capturedImages)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(child: _buildCameraArea()),

            if (capturedImages.isNotEmpty)
              _CapturedPagesBar(images: capturedImages, onDelete: _removeImage),

            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),

          const Expanded(
            child: Text(
              'Scan Pages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (capturedImages.isNotEmpty)
            TextButton(
              onPressed: _continue,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    if (isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMessage != null) {
      return _CameraErrorState(
        message: errorMessage!,
        onRetry: _initializeCamera,
      );
    }

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return _CameraErrorState(
        message: 'Camera could not be initialized.',
        onRetry: _initializeCamera,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _focusCamera(details, constraints);
              },
              child: _CameraPreview(controller: controller),
            ),

            // Document scanner guide.
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 74, 28, 72),
                child: CustomPaint(
                  painter: _DocumentFramePainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Visible tap-to-focus indicator.
            if (showFocusIndicator && focusPoint != null)
              Positioned(
                left: focusPoint!.dx - 30,
                top: focusPoint!.dy - 30,
                child: IgnorePointer(
                  child: _FocusIndicator(
                    key: ValueKey(
                      '${focusPoint!.dx}-${focusPoint!.dy}-$_focusRequestId',
                    ),
                  ),
                ),
              ),

            // Camera controls.
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CameraToolButton(
                    icon: flashMode == FlashMode.off
                        ? Icons.flash_off_rounded
                        : Icons.flash_on_rounded,
                    onTap: _toggleFlash,
                  ),

                  if (_cameras.length > 1) ...[
                    const SizedBox(width: 12),
                    _CameraToolButton(
                      icon: Icons.cameraswitch_rounded,
                      onTap: _switchCamera,
                    ),
                  ],
                ],
              ),
            ),

            // Camera hint / page counter.
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    capturedImages.isEmpty
                        ? 'Position the page inside the frame'
                        : '${capturedImages.length} page${capturedImages.length == 1 ? '' : 's'} captured',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.black,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: capturedImages.isNotEmpty
                ? Text(
                    '${capturedImages.length}\npages',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  )
                : null,
          ),

          Expanded(
            child: Center(
              child: _CaptureButton(
                isCapturing: isCapturing,
                onTap: _captureImage,
              ),
            ),
          ),

          SizedBox(
            width: 64,
            child: capturedImages.isNotEmpty
                ? IconButton(
                    onPressed: _continue,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final scale = 1 / (controller.value.aspectRatio * size.aspectRatio);

    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 : scale,
        alignment: Alignment.center,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onTap;

  const _CaptureButton({required this.isCapturing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isCapturing ? Colors.white54 : Colors.white,
            shape: BoxShape.circle,
          ),
          child: isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _CameraToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CameraToolButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CapturedPagesBar extends StatelessWidget {
  final List<XFile> images;

  final void Function(int index) onDelete;

  const _CapturedPagesBar({required this.images, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      color: const Color(0xFF111111),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(images[index].path),
                  width: 58,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () {
                    onDelete(index);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraErrorState extends StatelessWidget {
  final String message;

  final Future<void> Function({int cameraIndex}) onRetry;

  const _CameraErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white70,
              size: 52,
            ),

            const SizedBox(height: 18),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 34.0;

    // Top-left.
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right.
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left.
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom-right.
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _FocusIndicator extends StatefulWidget {
  const _FocusIndicator({super.key});

  @override
  State<_FocusIndicator> createState() => _FocusIndicatorState();
}

class _FocusIndicatorState extends State<_FocusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scale = Tween<double>(begin: 1.35, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 5,
            height: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
