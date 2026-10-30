import 'package:flutter/material.dart';

import 'finora_store.dart';
import 'finora_theme.dart';
import 'setup_screen.dart';
import 'finora_logo.dart';
import 'app_colors.dart';

/// First screen for new users: introduces Finora, then starts the setup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SetupScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Stack(
        children: [
          const Positioned(
            top: -140,
            right: -190,
            child: _Glow(size: 420, color: cyan, alpha: 0.28),
          ),
          const Positioned(
            bottom: -150,
            left: -170,
            child: _Glow(size: 440, color: emerald, alpha: 0.2),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 8),
                  const _Hero(),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Take Control\nof Your '),
                        TextSpan(
                          text: 'Money',
                          style: TextStyle(color: emerald),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 32,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track expenses, manage budgets, and understand your '
                    'spending habits — all in one simple place.',
                    style: TextStyle(
                      color: context.muted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Features(),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => _start(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => FinoraScope.of(context).skipSetup(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.ink,
                      backgroundColor: context.surface,
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: context.line, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Your finances. Your control. Your privacy.',
                      style: TextStyle(
                        color: context.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FinoraLogo(size: 44),
      SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finora',
            style: TextStyle(
              color: context.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Your money. Your control.',
            style: TextStyle(color: context.muted, fontSize: 12),
          ),
        ],
      ),
    ],
  );
}

/// A small phone-with-dashboard, wallet and growth-card illustration.
class _Hero extends StatelessWidget {
  const _Hero();

  static const _shadow = [
    BoxShadow(color: Color(0x2014213D), blurRadius: 24, offset: Offset(0, 10)),
  ];

  Widget _coin(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white70, width: size * 0.12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  emerald.withValues(alpha: 0.24),
                  emerald.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 132,
            height: 220,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.primary,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _shadow,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 26, 14, 12),
              decoration: BoxDecoration(
                color: context.subtle,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total spent',
                    style: TextStyle(color: context.muted, fontSize: 8),
                  ),
                  Text(
                    'LKR 45,000',
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: 0.6,
                        strokeWidth: 9,
                        color: emerald,
                        backgroundColor: context.line,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (final (color, w) in [
                    (emerald, 0.8),
                    (cyan, 0.55),
                    (context.ink, 0.35),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: w,
                          minHeight: 6,
                          color: color,
                          backgroundColor: context.line,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(left: 70, bottom: 58, child: _coin(38, cyan)),
          Positioned(left: 112, bottom: 52, child: _coin(30, emerald)),
          Positioned(right: 30, bottom: 6, child: _coin(26, emerald)),
          Positioned(left: 20, top: 40, child: _coin(18, emerald)),
          Positioned(
            left: 52,
            bottom: 4,
            child: Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: emerald,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3810B981),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.16),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: 42,
                    child: Container(
                      width: 44,
                      height: 28,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 11),
                      decoration: BoxDecoration(
                        color: context.primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.receipt_long_rounded,
        emerald,
        Color(0xFFE1F9F1),
        'Track Expenses',
        'Record every rupee.',
      ),
      (
        Icons.pie_chart_rounded,
        Color(0xFF0EA5E9),
        Color(0xFFE0F4FE),
        'Smart Budgets',
        'Stay within your limits.',
      ),
      (
        Icons.bar_chart_rounded,
        navy,
        Color(0xFFE8ECF4),
        'Spending Insights',
        'Understand where your money goes.',
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: context.subtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: items[i].$3,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(items[i].$1, color: items[i].$2, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items[i].$4,
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$5,
                      style: TextStyle(
                        color: context.muted,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
