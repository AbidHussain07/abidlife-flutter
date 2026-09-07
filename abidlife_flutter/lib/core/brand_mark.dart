import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ABIDLIFE',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF9745F5), Color(0xFF35187F)],
          ),
          borderRadius: BorderRadius.circular(size * .29),
        ),
        child: CustomPaint(painter: _BrandPainter()),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final crown = Path()
      ..moveTo(w * .30, h * .29)
      ..lineTo(w * .33, h * .18)
      ..lineTo(w * .42, h * .24)
      ..lineTo(w * .50, h * .13)
      ..lineTo(w * .58, h * .24)
      ..lineTo(w * .67, h * .18)
      ..lineTo(w * .70, h * .29)
      ..close();
    canvas.drawPath(crown, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .30, h * .31, w * .40, h * .035),
        Radius.circular(w * .02),
      ),
      paint,
    );

    final a = Path()
      ..moveTo(w * .22, h * .84)
      ..lineTo(w * .47, h * .39)
      ..quadraticBezierTo(w * .50, h * .34, w * .53, h * .39)
      ..lineTo(w * .78, h * .84)
      ..lineTo(w * .64, h * .84)
      ..lineTo(w * .58, h * .71)
      ..lineTo(w * .42, h * .71)
      ..lineTo(w * .36, h * .84)
      ..close();
    canvas.drawPath(a, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
