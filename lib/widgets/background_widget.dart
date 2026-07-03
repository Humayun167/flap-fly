// lib/widgets/background_widget.dart
import 'package:flutter/material.dart';

class BackgroundWidget extends StatefulWidget {
  final double groundOffset;
  final bool isPlaying;

  const BackgroundWidget({
    super.key,
    required this.groundOffset,
    required this.isPlaying,
  });

  @override
  State<BackgroundWidget> createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sky gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
                Color(0xFF80DEEA),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Clouds
        AnimatedBuilder(
          animation: _cloudController,
          builder: (_, __) {
            return CustomPaint(
              size: Size.infinite,
              painter: _CloudPainter(_cloudController.value),
            );
          },
        ),

        // Ground
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: CustomPaint(
            painter: _GroundPainter(widget.groundOffset),
          ),
        ),
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double offset;
  _CloudPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    final clouds = [
      (0.1, 0.15, 60.0),
      (0.4, 0.08, 80.0),
      (0.7, 0.2, 50.0),
      (0.9, 0.12, 70.0),
    ];

    for (var (baseX, y, radius) in clouds) {
      final x = ((baseX - offset * 0.05) % 1.1) * size.width;
      _drawCloud(canvas, paint, x, y * size.height, radius);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, double x, double y, double r) {
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 0.7, y + r * 0.1), r * 0.75, paint);
    canvas.drawCircle(Offset(x - r * 0.7, y + r * 0.1), r * 0.65, paint);
    canvas.drawCircle(Offset(x + r * 0.3, y - r * 0.4), r * 0.6, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.offset != offset;
}

class _GroundPainter extends CustomPainter {
  final double offset;
  _GroundPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Dirt base
    canvas.drawRect(
      Rect.fromLTWH(0, 16, size.width, size.height),
      Paint()..color = const Color(0xFFDEB887),
    );

    // Grass
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 20),
      Paint()..color = const Color(0xFF4CAF50),
    );

    // Grass stripe
    canvas.drawRect(
      Rect.fromLTWH(0, 12, size.width, 8),
      Paint()..color = const Color(0xFF388E3C),
    );

    // Ground marks
    final markPaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final step = size.width / 8;
    for (int i = 0; i < 10; i++) {
      final x = (i * step - offset * size.width) % size.width;
      canvas.drawLine(Offset(x, 20), Offset(x + step * 0.4, 20), markPaint);
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.offset != offset;
}
