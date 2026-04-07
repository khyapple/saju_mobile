import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 코스믹 그라데이션 배경 위젯 (별빛 깜빡임 애니메이션 포함)
class CosmicBackground extends StatelessWidget {
  final Widget child;
  final bool showStars;
  final List<Color>? gradientColors;

  const CosmicBackground({
    super.key,
    required this.child,
    this.showStars = true,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors ?? const [
            kCosmicDeep,
            kCosmicNavy,
            kCosmicPurple,
            kCosmicDeep,
          ],
          stops: const [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: showStars
          ? Stack(
              children: [
                const Positioned.fill(child: AnimatedStarField()),
                child,
              ],
            )
          : child,
    );
  }
}

/// 애니메이션 별빛 — 불규칙한 깜빡임
class AnimatedStarField extends StatefulWidget {
  /// 별 개수
  final int starCount;

  /// 큰 글로우 별 개수
  final int glowStarCount;

  const AnimatedStarField({
    super.key,
    this.starCount = 120,
    this.glowStarCount = 6,
  });

  @override
  State<AnimatedStarField> createState() => _AnimatedStarFieldState();
}

class _AnimatedStarFieldState extends State<AnimatedStarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_StarSpec> _stars;
  late final List<_StarSpec> _glowStars;

  @override
  void initState() {
    super.initState();
    // 30초 주기로 천천히 도는 마스터 시계 (각 별은 자기만의 주기로 깜빡임)
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // 별의 위치/주기/위상을 미리 생성 (매 프레임 재계산 방지)
    final rng = Random(42);
    _stars = List.generate(widget.starCount, (_) => _StarSpec.random(rng));
    _glowStars = List.generate(widget.glowStarCount, (_) => _StarSpec.glow(rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _AnimatedStarPainter(
            time: _ctrl.value * 30, // 0~30초
            stars: _stars,
            glowStars: _glowStars,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// 별 한 개의 고정 속성
class _StarSpec {
  final double xRatio;     // 0~1, 화면 너비 비율
  final double yRatio;     // 0~1, 화면 높이 비율
  final double baseRadius; // 기본 반지름
  final double speed;      // 깜빡임 속도 (Hz, 초당 사이클 수)
  final double phase;      // 위상 오프셋
  final double phase2;     // 두 번째 위상 (하모닉 합성)
  final double speed2;     // 두 번째 속도
  final double minOpacity; // 최소 밝기
  final double maxOpacity; // 최대 밝기

  const _StarSpec({
    required this.xRatio,
    required this.yRatio,
    required this.baseRadius,
    required this.speed,
    required this.phase,
    required this.phase2,
    required this.speed2,
    required this.minOpacity,
    required this.maxOpacity,
  });

  factory _StarSpec.random(Random rng) {
    return _StarSpec(
      xRatio: rng.nextDouble(),
      yRatio: rng.nextDouble(),
      baseRadius: rng.nextDouble() * 1.2 + 0.3,
      // 0.05~0.3 Hz: 별마다 깜빡이는 주기가 매우 다름 (3~20초)
      speed: rng.nextDouble() * 0.25 + 0.05,
      phase: rng.nextDouble(),
      phase2: rng.nextDouble(),
      // 두 번째 하모닉: 더 빠른 미세 흔들림
      speed2: rng.nextDouble() * 0.4 + 0.2,
      minOpacity: rng.nextDouble() * 0.1 + 0.05,
      maxOpacity: rng.nextDouble() * 0.4 + 0.4,
    );
  }

  factory _StarSpec.glow(Random rng) {
    return _StarSpec(
      xRatio: rng.nextDouble(),
      yRatio: rng.nextDouble(),
      baseRadius: rng.nextDouble() * 1.0 + 1.2,
      speed: rng.nextDouble() * 0.15 + 0.05, // 천천히 (6~20초)
      phase: rng.nextDouble(),
      phase2: rng.nextDouble(),
      speed2: rng.nextDouble() * 0.2 + 0.1,
      minOpacity: 0.3,
      maxOpacity: 0.85,
    );
  }
}

class _AnimatedStarPainter extends CustomPainter {
  final double time; // 초 단위
  final List<_StarSpec> stars;
  final List<_StarSpec> glowStars;

  _AnimatedStarPainter({
    required this.time,
    required this.stars,
    required this.glowStars,
  });

  /// 두 sin 파형을 합성한 불규칙 깜빡임 (0.0~1.0)
  double _twinkle(_StarSpec s) {
    final w1 = sin((time * s.speed + s.phase) * 2 * pi);
    final w2 = sin((time * s.speed2 + s.phase2) * 2 * pi);
    // 두 파형을 7:3 비율로 합성 → -1~1
    final mixed = w1 * 0.7 + w2 * 0.3;
    // 0~1로 정규화
    return (mixed + 1) / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 작은 별들
    for (final s in stars) {
      final t = _twinkle(s);
      final opacity = s.minOpacity + (s.maxOpacity - s.minOpacity) * t;
      final radius = s.baseRadius * (0.85 + t * 0.3);

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(s.xRatio * size.width, s.yRatio * size.height),
        radius,
        paint,
      );
    }

    // 큰 글로우 별
    for (final s in glowStars) {
      final t = _twinkle(s);
      final center = Offset(s.xRatio * size.width, s.yRatio * size.height);
      final glowRadius = s.baseRadius * (5 + t * 4);

      // 외곽 골드 글로우
      paint.color = kGold.withOpacity(0.04 + t * 0.06);
      canvas.drawCircle(center, glowRadius, paint);

      // 중간 보라 글로우
      paint.color = kCosmicViolet.withOpacity(0.05 + t * 0.05);
      canvas.drawCircle(center, glowRadius * 0.5, paint);

      // 별 중심
      paint.color = Colors.white.withOpacity(s.minOpacity + (s.maxOpacity - s.minOpacity) * t);
      canvas.drawCircle(center, s.baseRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedStarPainter old) => old.time != time;
}
