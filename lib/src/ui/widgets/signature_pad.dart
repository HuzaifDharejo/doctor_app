import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A signature pad widget for capturing handwritten signatures
class SignaturePad extends StatefulWidget {
  final String? initialSignature; // Base64 encoded signature
  final ValueChanged<String?> onSignatureChanged;
  final double height;
  final Color strokeColor;
  final double strokeWidth;
  final bool readOnly;

  const SignaturePad({
    super.key,
    this.initialSignature,
    required this.onSignatureChanged,
    this.height = 200,
    this.strokeColor = const Color(0xFF1E3A8A),
    this.strokeWidth = 2.5,
    this.readOnly = false,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _hasSignature = widget.initialSignature != null && widget.initialSignature!.isNotEmpty;
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.readOnly) return;
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSignature = false; // Clear initial signature when drawing
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.readOnly) return;
    setState(() {
      _currentStroke = [..._currentStroke, details.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails details) async {
    if (widget.readOnly) return;
    setState(() {
      _strokes = [..._strokes, _currentStroke];
      _currentStroke = [];
    });
    await _saveSignature();
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) {
      widget.onSignatureChanged(null);
      return;
    }

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final paint = Paint()
        ..color = widget.strokeColor
        ..strokeWidth = widget.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Draw all strokes
      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, widget.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final base64 = base64Encode(byteData.buffer.asUint8List());
        widget.onSignatureChanged(base64);
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
      _hasSignature = false;
    });
    widget.onSignatureChanged(null);
  }

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
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Background pattern
                CustomPaint(
                  size: Size.infinite,
                  painter: _SignatureBackgroundPainter(
                    isDark: isDark,
                  ),
                ),
                
                // Drawing area - always show GestureDetector for interaction
                GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: _hasSignature && widget.initialSignature != null
                      ? Center(
                          child: _buildSignatureImage(widget.initialSignature!),
                        )
                      : CustomPaint(
                          size: Size.infinite,
                          painter: _SignaturePainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                            strokeColor: widget.strokeColor,
                            strokeWidth: widget.strokeWidth,
                          ),
                        ),
                ),
                
                // Placeholder text
                if (_strokes.isEmpty && !_hasSignature)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.draw_outlined,
                          size: 40,
                          color: isDark 
                              ? AppColors.darkTextHint 
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.readOnly 
                              ? 'No signature' 
                              : 'Draw your signature here',
                          style: TextStyle(
                            color: isDark 
                                ? AppColors.darkTextHint 
                                : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Clear button
                if ((_strokes.isNotEmpty || _hasSignature) && !widget.readOnly)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _clearSignature,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 20,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'This signature will appear on prescriptions and invoices',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSignatureImage(String base64Data) {
    try {
      final bytes = base64Decode(base64Data);
      return Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.contain,
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw all completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        // Smooth the line using quadratic bezier curves
        if (i < stroke.length - 1) {
          final xc = (stroke[i].dx + stroke[i + 1].dx) / 2;
          final yc = (stroke[i].dy + stroke[i + 1].dy) / 2;
          path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, xc, yc);
        } else {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}

class _SignatureBackgroundPainter extends CustomPainter {
  final bool isDark;

  _SignatureBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    // Draw horizontal lines
    const spacing = 20.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw a baseline
    final baselinePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1)
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      Offset(20, size.height - 40),
      Offset(size.width - 20, size.height - 40),
      baselinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact signature preview widget for displaying saved signatures
class SignaturePreview extends StatelessWidget {
  final String? signatureData;
  final double height;
  final VoidCallback? onTap;

  const SignaturePreview({
    super.key,
    this.signatureData,
    this.height = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: signatureData != null && signatureData!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _buildSignatureImage(signatureData!),
              )
            : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw,
                      size: 18,
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to add signature',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSignatureImage(String base64Data) {
    try {
      final bytes = base64Decode(base64Data);
      return Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.contain,
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}
