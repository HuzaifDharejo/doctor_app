import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

/// A signature pad widget for capturing handwritten signatures
class SignaturePad extends StatefulWidget {

  const SignaturePad({
    required this.onSignatureChanged, super.key,
    this.initialSignature,
    this.height = 200,
    this.strokeColor = const Color(0xFF1E3A8A),
    this.strokeWidth = 3.0,
    this.readOnly = false,
  });
  final String? initialSignature;
  final ValueChanged<String?> onSignatureChanged;
  final double height;
  final Color strokeColor;
  final double strokeWidth;
  final bool readOnly;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasInitialSignature = false;
  Uint8List? _initialImageBytes;
  bool _isDrawing = false;
  Uint8List? _capturedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isOrientationLocked = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSignature();
  }

  @override
  void dispose() {
    // Restore all orientations when signature pad is closed
    if (_isOrientationLocked) {
      _unlockOrientation();
    }
    super.dispose();
  }

  Future<void> _lockOrientation() async {
    if (_isOrientationLocked) return;
    _isOrientationLocked = true;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _unlockOrientation() async {
    _isOrientationLocked = false;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _loadInitialSignature() {
    if (widget.initialSignature != null && widget.initialSignature!.isNotEmpty) {
      try {
        final data = jsonDecode(widget.initialSignature!);
        if (data is Map && data['strokes'] != null) {
          final strokesData = data['strokes'] as List;
          _strokes = strokesData.map((stroke) {
            return (stroke as List).map((point) {
              return Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble());
            }).toList();
          }).toList();
          setState(() {});
          return;
        }
        // Check if it's image data
        if (data is Map && data['image'] != null) {
          _capturedImageBytes = base64Decode(data['image'] as String);
          setState(() {});
          return;
        }
      } catch (_) {
        try {
          _initialImageBytes = base64Decode(widget.initialSignature!);
          _hasInitialSignature = true;
          setState(() {});
        } catch (_) {}
      }
    }
  }

  Future<void> _captureFromCamera() async {
    // Lock screen orientation when using camera
    unawaited(_lockOrientation());
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _strokes = [];
          _currentStroke = [];
          _hasInitialSignature = false;
          _initialImageBytes = null;
        });
        // Save as base64 image
        widget.onSignatureChanged(jsonEncode({'image': base64Encode(bytes)}));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // Lock screen orientation when using gallery
    unawaited(_lockOrientation());
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _strokes = [];
          _currentStroke = [];
          _hasInitialSignature = false;
          _initialImageBytes = null;
        });
        // Save as base64 image
        widget.onSignatureChanged(jsonEncode({'image': base64Encode(bytes)}));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.readOnly) return;
    // Lock screen orientation when user starts drawing
    _lockOrientation();
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(event.position);
    setState(() {
      _isDrawing = true;
      _currentStroke = [localPosition];
      _hasInitialSignature = false;
      _initialImageBytes = null;
      _capturedImageBytes = null;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.readOnly || !_isDrawing) return;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(event.position);
    setState(() {
      _currentStroke = [..._currentStroke, localPosition];
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.readOnly || !_isDrawing) return;
    setState(() {
      _isDrawing = false;
      if (_currentStroke.isNotEmpty) {
        _strokes = [..._strokes, _currentStroke];
      }
      _currentStroke = [];
    });
    _saveSignature();
  }

  void _saveSignature() {
    if (_strokes.isEmpty) {
      widget.onSignatureChanged(null);
      return;
    }
    final strokesData = _strokes.map((stroke) {
      return stroke.map((point) => {'x': point.dx, 'y': point.dy}).toList();
    }).toList();
    widget.onSignatureChanged(jsonEncode({'strokes': strokesData}));
  }

  void _clearSignature() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
      _hasInitialSignature = false;
      _initialImageBytes = null;
      _capturedImageBytes = null;
      _isDrawing = false;
    });
    widget.onSignatureChanged(null);
  }

  bool get _hasAnySignature => 
      _strokes.isNotEmpty || 
      _hasInitialSignature || 
      _capturedImageBytes != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDrawing ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _SignatureBackgroundPainter(isDark: isDark))),
                Positioned.fill(
                  child: GestureDetector(
                    // Block all vertical/horizontal drags to prevent parent scroll
                    onVerticalDragStart: (_) {},
                    onVerticalDragUpdate: (_) {},
                    onVerticalDragEnd: (_) {},
                    onHorizontalDragStart: (_) {},
                    onHorizontalDragUpdate: (_) {},
                    onHorizontalDragEnd: (_) {},
                    child: Listener(
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerUp,
                      behavior: HitTestBehavior.opaque,
                      child: _capturedImageBytes != null
                          ? Center(child: Image.memory(_capturedImageBytes!, fit: BoxFit.contain))
                          : _hasInitialSignature && _initialImageBytes != null
                              ? Center(child: Image.memory(_initialImageBytes!, fit: BoxFit.contain))
                              : CustomPaint(painter: _SignaturePainter(strokes: _strokes, currentStroke: _currentStroke, strokeColor: widget.strokeColor, strokeWidth: widget.strokeWidth)),
                    ),
                  ),
                ),
                if (_strokes.isEmpty && _currentStroke.isEmpty && !_hasInitialSignature && _capturedImageBytes == null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw_outlined, size: 40, color: isDark ? AppColors.darkTextHint : AppColors.textHint),
                            const SizedBox(height: 8),
                            Text(widget.readOnly ? 'No signature' : 'Draw your signature here', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint, fontSize: 14)),
                            if (!widget.readOnly) ...[
                              const SizedBox(height: 4),
                              Text('or use camera/gallery below', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_hasAnySignature && !widget.readOnly)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _clearSignature,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.clear, size: 20, color: AppColors.error),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: _captureFromCamera,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.info_outline, size: 14, color: isDark ? AppColors.darkTextHint : AppColors.textHint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Draw signature, capture from camera, or pick from gallery',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextHint : AppColors.textHint),
              ),
            ),
          ],),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {

  _SignaturePainter({required this.strokes, required this.currentStroke, required this.strokeColor, required this.strokeWidth});
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = strokeColor..strokeWidth = strokeWidth..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        if (i < stroke.length - 1) {
          path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, (stroke[i].dx + stroke[i + 1].dx) / 2, (stroke[i].dy + stroke[i + 1].dy) / 2);
        } else {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    if (currentStroke.length >= 2) {
      final path = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => strokes != oldDelegate.strokes || currentStroke != oldDelegate.currentStroke;
}

class _SignatureBackgroundPainter extends CustomPainter {
  _SignatureBackgroundPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.05)..strokeWidth = 1;
    for (double y = 20; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final baselinePaint = Paint()..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.15)..strokeWidth = 2;
    canvas.drawLine(Offset(20, size.height - 40), Offset(size.width - 20, size.height - 40), baselinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SignaturePreview extends StatelessWidget {

  const SignaturePreview({super.key, this.signatureData, this.height = 80, this.onTap});
  final String? signatureData;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider)),
        child: signatureData != null && signatureData!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(11), child: _buildSignatureWidget(signatureData!, isDark))
            : Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.draw, size: 18, color: isDark ? AppColors.darkTextHint : AppColors.textHint), const SizedBox(width: 8), Text('Tap to add signature', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint, fontSize: 13))])),
      ),
    );
  }

  Widget _buildSignatureWidget(String data, bool isDark) {
    try {
      final jsonData = jsonDecode(data);
      if (jsonData is Map) {
        // Handle strokes format
        if (jsonData['strokes'] != null) {
          final strokes = (jsonData['strokes'] as List).map((stroke) => (stroke as List).map((point) => Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble())).toList()).toList();
          return CustomPaint(size: Size.infinite, painter: _SignaturePainter(strokes: strokes, currentStroke: [], strokeColor: const Color(0xFF1E3A8A), strokeWidth: 2.5));
        }
        // Handle image format
        if (jsonData['image'] != null) {
          final imageBytes = base64Decode(jsonData['image'] as String);
          return Image.memory(imageBytes, fit: BoxFit.contain);
        }
      }
    } catch (_) {
      try { return Image.memory(Uint8List.fromList(base64Decode(data)), fit: BoxFit.contain); } catch (_) {}
    }
    return const SizedBox();
  }
}
