import 'package:flutter/material.dart';

import 'finora_store.dart';
import 'finora_theme.dart';
import 'setup_screen.dart';

/// First screen for new users: introduces Finora, then starts the setup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SetupScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: emerald,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Brand(),
              const Expanded(child: Center(child: _Illustration())),
              const Text(
                'Know where\nevery rupee\ngoes',
                style: TextStyle(
                  color: navy,
                  fontSize: 42,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: const Text(
                  'Record expenses, set a monthly budget and category '
                  'limits, and get alerts before you overspend. Everything '
                  'stays on your phone.',
                  style: TextStyle(
                    color: Color(0xFF2B3320),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => FinoraScope.of(context).skipSetup(),
                    style: TextButton.styleFrom(
                      foregroundColor: navy,
                      minimumSize: const Size(64, 48),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                  InkWell(
                    onTap: () => _start(context),
                    borderRadius: BorderRadius.circular(40),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Let's Start",
                          style: TextStyle(
                            color: navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: navy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            color: emerald,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.bar_chart_rounded, color: emerald, size: 20),
      ),
      const SizedBox(width: 10),
      const Text(
        'Finora',
        style: TextStyle(
          color: navy,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// A wallet-and-coins illustration on a darker lime disc.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    height: 300,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 270,
          height: 270,
          decoration: const BoxDecoration(
            color: limeDeep,
            shape: BoxShape.circle,
          ),
        ),
        CustomPaint(size: const Size(300, 300), painter: _WalletPainter()),
        Positioned(
          top: 18,
          right: 6,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pie_chart_rounded, color: emerald),
          ),
        ),
      ],
    ),
  );
}

class _WalletPainter extends CustomPainter {
  static const _cream = Color(0xFFFBFFE8);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    // Wallet body.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 104, 196, 136),
      const Radius.circular(28),
    );
    canvas.drawRRect(body, fill(_cream));
    canvas.drawRRect(body, stroke);

    // Clasp.
    final clasp = RRect.fromRectAndRadius(
      const Rect.fromLTWH(170, 150, 78, 52),
      const Radius.circular(18),
    );
    canvas.drawRRect(clasp, fill(emerald));
    canvas.drawRRect(clasp, stroke);
    canvas.drawCircle(const Offset(198, 176), 6, fill(navy));

    // Big coin.
    canvas.drawCircle(const Offset(222, 64), 30, fill(_cream));
    canvas.drawCircle(const Offset(222, 64), 30, stroke);
    canvas.drawLine(const Offset(222, 50), const Offset(222, 78), stroke);

    // Small coin with a plus.
    canvas.drawCircle(const Offset(96, 70), 16, fill(navy));
    final plus = Paint()
      ..color = emerald
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(90, 70), const Offset(102, 70), plus);
    canvas.drawLine(const Offset(96, 64), const Offset(96, 76), plus);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
