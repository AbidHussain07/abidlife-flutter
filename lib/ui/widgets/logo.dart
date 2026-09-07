import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ABIDLIFE brand mark — a bold "A" crowned with a small minimal crown.
///
/// Renders the SVG bundled at `assets/icon.svg` so the same vector asset is
/// reused on the splash, onboarding and settings sheets.
class LumaLogo extends StatelessWidget {
  const LumaLogo({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/icon.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// A pure-SVG fallback that doesn't require the bundled asset — used during
/// tests and anywhere `flutter_svg` cannot resolve the asset bundle.
class LumaLogoPainter extends CustomPainter {
  LumaLogoPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;
    canvas.save();
    canvas.scale(s);

    final paint = Paint()..color = color;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Background rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 48, 48),
        const Radius.circular(13),
      ),
      paint,
    );

    // Crown
    final crown = Path()
      ..moveTo(17.6, 14.4)
      ..lineTo(19.2, 9.1)
      ..lineTo(22, 11.8)
      ..lineTo(24, 7.2)
      ..lineTo(26, 11.8)
      ..lineTo(28.8, 9.1)
      ..lineTo(30.4, 14.4)
      ..close();
    canvas.drawPath(crown, Paint()..color = Colors.white);

    // Crown bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17.6, 15.2, 12.8, 2.1),
        const Radius.circular(1.05),
      ),
      Paint()..color = Colors.white,
    );

    // Letter A
    canvas.drawPath(
      Path()
        ..moveTo(15, 37)
        ..lineTo(24, 19)
        ..lineTo(33, 37),
      stroke,
    );
    canvas.drawLine(
      const Offset(19.1, 30.6),
      const Offset(28.9, 30.6),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.9
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LumaLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
