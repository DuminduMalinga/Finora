import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finora_theme.dart';

const cyan = Color(0xFF38BDF8);

/// The Finora app icon: a coin ring that opens where a growth arrow exits,
/// with a wallet inside, on navy. Drawn on a 120-unit grid and scaled.
class FinoraLogo extends StatelessWidget {
  const FinoraLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final fill = Paint()..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 120, 120),
        const Radius.circular(28),
      ),
      fill..color = navy,
    );

    // Coin ring with a gap at the top right.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(60, 60), radius: 34.75),
      -math.pi / 6,
      math.pi * 310 / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..color = emerald
        ..isAntiAlias = true,
    );

    // Wallet.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 56, 44, 28),
        const Radius.circular(8),
      ),
      fill..color = emerald,
    );
    canvas.drawRect(const Rect.fromLTWH(38, 63, 44, 3), fill..color = navy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(63.5, 65.5, 25, 17),
        const Radius.circular(8.5),
      ),
      fill..color = emerald,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 68, 20, 12),
        const Radius.circular(6),
      ),
      fill..color = navy,
    );
    canvas.drawCircle(const Offset(76, 74), 3, fill..color = cyan);

    // Growth arrow.
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = cyan
      ..isAntiAlias = true;
    canvas.drawPath(
      Path()
        ..moveTo(40, 48)
        ..lineTo(55, 36)
        ..lineTo(64, 44)
        ..lineTo(86, 24)
        ..moveTo(74, 24)
        ..lineTo(86, 24)
        ..lineTo(86, 36),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
