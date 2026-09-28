import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class MoneyBackground extends StatelessWidget {
  final Widget child;
  const MoneyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _MoneyPainter())),
        child,
      ],
    );
  }
}

class _MoneyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final symbols = ['₣', '€', '\$', '£', '¥', '₵'];
    final rnd = math.Random(7);
    for (var i = 0; i < 30; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: symbols[i % symbols.length],
          style: TextStyle(
            fontSize: 16 + rnd.nextDouble() * 26,
            color: AppColors.primary.withOpacity(0.045 + rnd.nextDouble() * 0.03),
            fontWeight: FontWeight.w300,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.rotate((rnd.nextDouble() - 0.5) * 0.5);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
