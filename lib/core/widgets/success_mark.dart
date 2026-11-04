import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';

class SuccessMark extends StatefulWidget {
  const SuccessMark({this.size = 96, super.key});

  final double size;

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.positive;
    return Semantics(
      label: 'Success',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _SuccessPainter(progress: _controller.value, color: color),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  const _SuccessPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = Curves.easeOutCubic.transform(
      (progress / 0.6).clamp(0.0, 1.0),
    );
    final check = Curves.easeOut.transform(
      ((progress - 0.45) / 0.55).clamp(0.0, 1.0),
    );
    canvas.drawCircle(
      center,
      radius * ring,
      Paint()..color = color.withValues(alpha: 0.14),
    );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      stroke,
    );
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.52)
      ..lineTo(size.width * 0.46, size.height * 0.63)
      ..lineTo(size.width * 0.67, size.height * 0.40);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * check), stroke);
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
