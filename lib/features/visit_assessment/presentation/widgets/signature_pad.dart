import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

class AssessmentSignaturePad extends StatefulWidget {
  const AssessmentSignaturePad({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<AssessmentSignaturePad> createState() => _AssessmentSignaturePadState();
}

class _AssessmentSignaturePadState extends State<AssessmentSignaturePad> {
  final _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _showInitial = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: GestureDetector(
            onPanStart: (details) => _addPoint(details.localPosition),
            onPanUpdate: (details) => _addPoint(details.localPosition),
            onPanEnd: (_) {
              setState(() => _points.add(null));
              _capture();
            },
            child: Container(
              height: 118,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: assessmentBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _showInitial && widget.initialValue.isNotEmpty
                    ? AssessmentDataImage(
                        dataUrl: widget.initialValue,
                        fit: BoxFit.contain,
                      )
                    : CustomPaint(
                        painter: _SignaturePainter(_points),
                        size: Size.infinite,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _clear,
              style: TextButton.styleFrom(
                foregroundColor: assessmentGreenDark,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }

  void _addPoint(Offset point) {
    setState(() {
      _showInitial = false;
      _points.add(point);
    });
  }

  void _clear() {
    setState(() {
      _showInitial = false;
      _points.clear();
    });
    widget.onChanged('');
  }

  Future<void> _capture() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final bytes = data.buffer.asUint8List();
    widget.onChanged('data:image/png;base64,${base64Encode(bytes)}');
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1D252B)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    var drawing = false;
    for (final point in points) {
      if (point == null) {
        drawing = false;
        continue;
      }
      if (!drawing) {
        path.moveTo(point.dx, point.dy);
        drawing = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
