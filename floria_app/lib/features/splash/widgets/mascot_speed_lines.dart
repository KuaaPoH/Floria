import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Hiển thị Mascot kèm các vệt tốc độ mềm mại phía sau, đồng bộ với [controller].
class MascotWithSpeedLines extends StatelessWidget {
  const MascotWithSpeedLines({
    super.key,
    required this.controller,
    required this.mascotSlide,
    required this.mascotFade,
    required this.child,
  });

  final AnimationController controller;
  final Animation<Offset> mascotSlide;
  final Animation<double> mascotFade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: mascotSlide,
      child: FadeTransition(
        opacity: mascotFade,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, mascotChild) {
            final t = controller.value;

            // Tính toán độ mờ & độ dài vệt tốc độ theo 3 pha:
            // Phase 1 Enter: 0.00 -> 0.23 | Phase 2 Idle: 0.23 -> 0.77 | Phase 3 Exit: 0.77 -> 1.00
            final double trailOpacity = _computeTrailOpacity(t);
            final double trailLengthFactor = _computeTrailLengthFactor(t);

            // Hiệu ứng nhún/nổi rất nhẹ khi Mascot dừng ở giữa (Idle)
            final double idleFloatY = _computeIdleFloat(t);

            return Transform.translate(
              offset: Offset(0, idleFloatY),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (trailOpacity > 0.005)
                    Positioned(
                      left: -135,
                      right: 28,
                      top: 12,
                      bottom: 12,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SpeedLinesPainter(
                            opacity: trailOpacity,
                            lengthFactor: trailLengthFactor,
                            progress: t,
                          ),
                        ),
                      ),
                    ),
                  mascotChild!,
                ],
              ),
            );
          },
          child: child,
        ),
      ),
    );
  }

  /// Opacity của Speed Lines:
  /// - Enter (0.00 -> 0.23): hiện rõ lúc đầu, mờ dần về 0 khi Mascot hãm phanh vào giữa (0.16 -> 0.25)
  /// - Idle (0.25 -> 0.77): 0.0 hoàn toàn
  /// - Exit (0.77 -> 1.00): hiện lại mượt mà (0.77 -> 0.84), giữ và mờ dần khi ra khỏi màn hình (0.90 -> 1.00)
  double _computeTrailOpacity(double t) {
    if (t < 0.26) {
      if (t <= 0.05) {
        return Curves.easeOut.transform((t / 0.05).clamp(0.0, 1.0));
      }
      if (t <= 0.16) {
        return 1.0;
      }
      final fadeOut = ((t - 0.16) / (0.26 - 0.16)).clamp(0.0, 1.0);
      return 1.0 - Curves.easeInOut.transform(fadeOut);
    }

    if (t < 0.77) {
      return 0.0;
    }

    if (t <= 0.84) {
      final fadeIn = ((t - 0.77) / (0.84 - 0.77)).clamp(0.0, 1.0);
      return Curves.easeOut.transform(fadeIn);
    }
    if (t <= 0.90) {
      return 1.0;
    }
    final fadeOut = ((t - 0.90) / (1.00 - 0.90)).clamp(0.0, 1.0);
    return 1.0 - Curves.easeIn.transform(fadeOut);
  }

  /// Độ dài vệt tốc độ: ngắn dần khi vào giữa (Enter), dài dần khi tăng tốc rời màn hình (Exit).
  double _computeTrailLengthFactor(double t) {
    if (t < 0.26) {
      final decel = (t / 0.26).clamp(0.0, 1.0);
      return 1.0 - 0.35 * Curves.easeOut.transform(decel);
    }
    if (t >= 0.77) {
      final accel = ((t - 0.77) / 0.23).clamp(0.0, 1.0);
      return 0.72 + 0.48 * Curves.easeInQuad.transform(accel);
    }
    return 0.0;
  }

  /// Chuyển động nổi rất nhẹ (±2.5px) trong giai đoạn Idle để nhân vật có sức sống.
  double _computeIdleFloat(double t) {
    if (t <= 0.24 || t >= 0.76) return 0.0;
    final idleProgress = (t - 0.24) / (0.76 - 0.24);
    final envelope = math.sin(idleProgress * math.pi);
    return -2.5 * math.sin(idleProgress * math.pi * 2) * envelope;
  }
}

class _SpeedLineSpec {
  const _SpeedLineSpec({
    required this.yFraction,
    required this.rightAnchorFraction,
    required this.lengthRatio,
    required this.maxHalfThickness,
    required this.curveOffset,
    required this.color,
    required this.alpha,
  });

  final double yFraction;
  final double rightAnchorFraction;
  final double lengthRatio;
  final double maxHalfThickness;
  final double curveOffset;
  final Color color;
  final double alpha;
}

class _SpeedLinesPainter extends CustomPainter {
  const _SpeedLinesPainter({
    required this.opacity,
    required this.lengthFactor,
    required this.progress,
  });

  final double opacity;
  final double lengthFactor;
  final double progress;

  // 4 vệt tốc độ với độ dài, độ dày, độ cong và sắc độ xanh lá khác nhau
  static const List<_SpeedLineSpec> _lines = [
    _SpeedLineSpec(
      yFraction: 0.27,
      rightAnchorFraction: 0.72,
      lengthRatio: 0.78,
      maxHalfThickness: 3.4,
      curveOffset: -7.0,
      color: Color(0xFF6BCB77),
      alpha: 0.34,
    ),
    _SpeedLineSpec(
      yFraction: 0.44,
      rightAnchorFraction: 0.66,
      lengthRatio: 0.94,
      maxHalfThickness: 4.5,
      curveOffset: 5.0,
      color: Color(0xFF2E6F40),
      alpha: 0.26,
    ),
    _SpeedLineSpec(
      yFraction: 0.63,
      rightAnchorFraction: 0.68,
      lengthRatio: 0.85,
      maxHalfThickness: 3.8,
      curveOffset: -4.5,
      color: Color(0xFF8BD46E),
      alpha: 0.36,
    ),
    _SpeedLineSpec(
      yFraction: 0.81,
      rightAnchorFraction: 0.74,
      lengthRatio: 0.64,
      maxHalfThickness: 2.8,
      curveOffset: 4.0,
      color: Color(0xFF4CA364),
      alpha: 0.30,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.005 || size.width <= 0 || size.height <= 0) return;

    // Rung nhẹ tự nhiên theo thời gian để vệt không bị cứng
    final subtleWave = math.sin(progress * math.pi * 10);

    for (int i = 0; i < _lines.length; i++) {
      final spec = _lines[i];
      final headX = size.width * spec.rightAnchorFraction;
      final lineLength = (size.width * 0.52 * spec.lengthRatio * lengthFactor)
          .clamp(24.0, size.width * 0.75);
      final tailX = headX - lineLength;

      final baseY = size.height * spec.yFraction + subtleWave * (i.isEven ? 1.2 : -1.2);
      final ctrlX = (tailX + headX) * 0.5;
      final ctrlY = baseY + spec.curveOffset;

      final path = _buildTaperedCurvePath(
        tail: Offset(tailX, baseY + spec.curveOffset * 0.25),
        control: Offset(ctrlX, ctrlY),
        head: Offset(headX, baseY),
        maxHalfThickness: spec.maxHalfThickness,
      );

      final effectiveAlpha = (spec.alpha * opacity).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          Offset(tailX, baseY),
          Offset(headX, baseY),
          [
            spec.color.withValues(alpha: 0.0),
            spec.color.withValues(alpha: effectiveAlpha * 0.55),
            spec.color.withValues(alpha: effectiveAlpha),
          ],
          const [0.0, 0.55, 1.0],
        );

      canvas.drawPath(path, paint);
    }
  }

  /// Dựng Path cong thuôn nhọn về phía đuôi (tail) và tròn mềm ở phía gần Mascot (head).
  Path _buildTaperedCurvePath({
    required Offset tail,
    required Offset control,
    required Offset head,
    required double maxHalfThickness,
  }) {
    const int steps = 14;
    final List<Offset> upperPoints = [];
    final List<Offset> lowerPoints = [];

    for (int i = 0; i <= steps; i++) {
      final u = i / steps;
      final inv = 1.0 - u;

      // Điểm trên đường cong Quadratic Bezier
      final p = Offset(
        inv * inv * tail.dx + 2 * inv * u * control.dx + u * u * head.dx,
        inv * inv * tail.dy + 2 * inv * u * control.dy + u * u * head.dy,
      );

      // Pháp tuyến xấp xỉ theo hướng dọc để vệt nằm ngang mềm mại
      // Độ dày thuôn từ 0.3px ở đuôi -> maxHalfThickness gần đầu -> bo tròn ở mũi
      final taper = u < 0.85
          ? math.pow(u / 0.85, 0.75).toDouble()
          : math.cos(((u - 0.85) / 0.15) * (math.pi / 2));
      final halfW = 0.25 + maxHalfThickness * taper;

      upperPoints.add(Offset(p.dx, p.dy - halfW));
      lowerPoints.add(Offset(p.dx, p.dy + halfW));
    }

    final path = Path()..moveTo(upperPoints.first.dx, upperPoints.first.dy);
    for (int i = 1; i < upperPoints.length; i++) {
      path.lineTo(upperPoints[i].dx, upperPoints[i].dy);
    }
    for (int i = lowerPoints.length - 1; i >= 0; i--) {
      path.lineTo(lowerPoints[i].dx, lowerPoints[i].dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.lengthFactor != lengthFactor ||
        oldDelegate.progress != progress;
  }
}
