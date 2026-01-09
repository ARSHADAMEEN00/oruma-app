import 'package:flutter/material.dart';

/// Custom icon representing "Deceased" - Letter D with person and cross line
class DeceasedIcon extends StatelessWidget {
  final double size;
  final Color color;

  const DeceasedIcon({super.key, this.size = 24.0, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DeceasedIconPainter(color: color),
    );
  }
}

class _DeceasedIconPainter extends CustomPainter {
  final Color color;

  _DeceasedIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw letter "D" outline (semi-circle on right side)
    final dPath = Path();
    dPath.moveTo(size.width * 0.2, size.height * 0.15);
    dPath.lineTo(size.width * 0.2, size.height * 0.85);

    // Arc for the right side of D
    dPath.moveTo(size.width * 0.2, size.height * 0.15);
    dPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.15,
      size.width * 0.85,
      size.height * 0.5,
    );
    dPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.85,
      size.width * 0.2,
      size.height * 0.85,
    );

    canvas.drawPath(dPath, paint);

    // Draw person icon inside (simplified stick figure)
    final personPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.35),
      size.width * 0.08,
      personPaint,
    );

    // Body (simple vertical line)
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, size.height * 0.43),
      Offset(center.dx, size.height * 0.65),
      bodyPaint,
    );

    // Arms (horizontal line)
    canvas.drawLine(
      Offset(center.dx - size.width * 0.12, size.height * 0.52),
      Offset(center.dx + size.width * 0.12, size.height * 0.52),
      bodyPaint,
    );

    // Draw diagonal cross line (from top-left to bottom-right)
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
