import 'package:flutter/material.dart';

class CornerBorderWidget extends StatelessWidget {
  final Size size;
  final double cornerLength;
  final double borderRadius;
  final double strokeWidth;
  final Color color;

  const CornerBorderWidget({
    super.key,
    required this.size,
    this.cornerLength = 30,
    this.borderRadius = 10,
    this.strokeWidth = 4,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _RoundedLCornerPainter(
          cornerLength: cornerLength,
          borderRadius: borderRadius,
          strokeWidth: strokeWidth,
          color: color,
        ),
      ),
    );
  }
}

class _RoundedLCornerPainter extends CustomPainter {
  final double cornerLength;
  final double borderRadius;
  final double strokeWidth;
  final Color color;

  _RoundedLCornerPainter({
    required this.cornerLength,
    required this.borderRadius,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Clamp radius so it doesn't exceed half of cornerLength
    final r = borderRadius.clamp(0.0, cornerLength / 2);
    final strippedLength = (cornerLength - r);
    final w = size.width;
    final h = size.height;

    {
      // Top Left
      final path = Path();
      path.moveTo(0, strippedLength + r);
      path.relativeLineTo(0, -strippedLength);

      path.arcToPoint(
        Offset(0 + r, 0),
        radius: Radius.circular(r),
      );

      path.relativeLineTo(strippedLength, 0);
      canvas.drawPath(path, paint);
    }
    {
      // Top Right
      final path = Path();
      path.moveTo(w - cornerLength, 0);
      path.relativeLineTo(strippedLength, 0);

      path.arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
      );

      path.relativeLineTo(0, strippedLength);
      canvas.drawPath(path, paint);
    }
    {
      // Bottom Left
      final path = Path();
      path.moveTo(cornerLength, h);
      path.relativeLineTo(-strippedLength, 0);

      path.arcToPoint(
        Offset(0, h - r),
        radius: Radius.circular(r),
      );

      path.relativeLineTo(0, -strippedLength);
      canvas.drawPath(path, paint);
    }
    {
      // Bottom Right
      final path = Path();
      path.moveTo(w, h - cornerLength);
      path.relativeLineTo(0, strippedLength);

      path.arcToPoint(
        Offset(w - r, h),
        radius: Radius.circular(r),
      );

      path.relativeLineTo(-strippedLength, 0);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
