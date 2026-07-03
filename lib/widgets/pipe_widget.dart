// lib/widgets/pipe_widget.dart
import 'package:flutter/material.dart';
import '../models/pipe.dart';
import '../models/game_config.dart';

class PipeWidget extends StatelessWidget {
  final Pipe pipe;
  final double pipeGap;
  final Size screenSize;

  const PipeWidget({
    super.key,
    required this.pipe,
    required this.pipeGap,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final pipeX = (pipe.x + 1) / 2 * screenSize.width;
    final pipeW = GameConfig.pipeWidth / 2 * screenSize.width;

    final gapTopPx = pipe.topHeight * screenSize.height;
    final gapBottomPx = gapTopPx + pipeGap / 2 * screenSize.height;

    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: pipeX - pipeW,
          top: 0,
          width: pipeW * 2,
          height: gapTopPx,
          child: _PipeBody(isTop: true),
        ),
        // Bottom pipe
        Positioned(
          left: pipeX - pipeW,
          top: gapBottomPx,
          width: pipeW * 2,
          bottom: 0,
          child: _PipeBody(isTop: false),
        ),
      ],
    );
  }
}

class _PipeBody extends StatelessWidget {
  final bool isTop;
  const _PipeBody({required this.isTop});

  @override
  Widget build(BuildContext context) {
    const pipeGreen = Color(0xFF2E7D32);
    const pipeLightGreen = Color(0xFF43A047);
    const pipeDarkGreen = Color(0xFF1B5E20);
    const capHeight = 22.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Pipe body
        Positioned.fill(
          top: isTop ? 0 : capHeight,
          bottom: isTop ? capHeight : 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [pipeLightGreen, pipeGreen, pipeDarkGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
        // Cap
        Positioned(
          left: -6,
          right: -6,
          top: isTop ? null : 0,
          bottom: isTop ? 0 : null,
          height: capHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [pipeLightGreen, pipeGreen, pipeDarkGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: isTop
                  ? const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              )
                  : const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              border: Border.all(color: pipeDarkGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
