// lib/widgets/bird_widget.dart
import 'package:flutter/material.dart';
import '../models/game_config.dart';

class BirdWidget extends StatelessWidget {
  final double birdY;
  final double rotation;
  final bool isDead;
  final AnimationController deathAnimation;

  const BirdWidget({
    super.key,
    required this.birdY,
    required this.rotation,
    required this.isDead,
    required this.deathAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final birdPixelX = (GameConfig.birdX + 1) / 2 * size.width;
    final birdPixelY = (birdY + 1) / 2 * size.height;
    final birdSize = GameConfig.birdSize * size.width;

    return AnimatedBuilder(
      animation: deathAnimation,
      builder: (context, _) {
        double offsetX = 0;
        if (isDead) {
          offsetX = (deathAnimation.value * 20) *
              (deathAnimation.value % 0.2 > 0.1 ? 1 : -1);
        }

        return Positioned(
          left: birdPixelX - birdSize / 2 + offsetX,
          top: birdPixelY - birdSize / 2,
          width: birdSize,
          height: birdSize,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF8F00),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Eye
                  Positioned(
                    right: birdSize * 0.18,
                    top: birdSize * 0.15,
                    child: Container(
                      width: birdSize * 0.22,
                      height: birdSize * 0.22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: birdSize * 0.12,
                          height: birdSize * 0.12,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Beak
                  Positioned(
                    right: -2,
                    top: birdSize * 0.4,
                    child: Container(
                      width: birdSize * 0.2,
                      height: birdSize * 0.15,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7043),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Wing
                  Positioned(
                    left: birdSize * 0.1,
                    top: birdSize * 0.45,
                    child: Container(
                      width: birdSize * 0.4,
                      height: birdSize * 0.2,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
