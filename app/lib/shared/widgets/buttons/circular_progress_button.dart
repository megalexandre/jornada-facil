import 'dart:async';
import 'package:flutter/material.dart';

typedef CircularProgressButtonBuilder = Widget Function(
  BuildContext context,
  bool isPressed,
  Animation<double> progress,
  Animation<double> pulse,
);

class CircularProgressButton extends StatefulWidget {
  final Duration completionDuration;
  final Duration pulseDuration;
  final VoidCallback onCompleted;
  final bool enabled;
  final CircularProgressButtonBuilder builder;

  const CircularProgressButton({
    super.key,
    this.completionDuration = const Duration(seconds: 2),
    this.pulseDuration = const Duration(milliseconds: 600),
    required this.onCompleted,
    this.enabled = true,
    required this.builder,
  });

  @override
  State<CircularProgressButton> createState() => _CircularProgressButtonState();
}

class _CircularProgressButtonState extends State<CircularProgressButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  bool _isPressed = false;
  Timer? _pressTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: widget.completionDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _pressTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;

    setState(() => _isPressed = true);
    _progressController.forward();
    _pulseController.repeat(reverse: true);

    _pressTimer = Timer(widget.completionDuration, () {
      if (_isPressed && mounted) {
        widget.onCompleted();
        _resetAnimation();
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _resetAnimation();
  }

  void _resetAnimation() {
    setState(() => _isPressed = false);
    _progressController.reset();
    _pulseController.reset();
    _pressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: widget.builder(
        context,
        _isPressed,
        _progressController,
        _pulseController,
      ),
    );
  }
}

class CircularBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularBorderPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 80.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      progress * 2 * 3.14159,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
