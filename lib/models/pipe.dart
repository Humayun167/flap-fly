// lib/models/pipe.dart

class Pipe {
  double x;
  double topHeight; // 0.0 to 1.0 (fraction of screen)
  bool passed;

  Pipe({
    required this.x,
    required this.topHeight,
    this.passed = false,
  });

  Pipe copyWith({double? x, double? topHeight, bool? passed}) {
    return Pipe(
      x: x ?? this.x,
      topHeight: topHeight ?? this.topHeight,
      passed: passed ?? this.passed,
    );
  }
}
