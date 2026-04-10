import 'package:flutter/material.dart';

/// 골드 구분선 위젯
/// 중앙 장식 문양(divider_center) 양쪽에 직선(divider_line) 1개씩 연장
/// — 이미지 비율 유지, 높이에 맞춰 크기 결정
class DancheongBar extends StatelessWidget {
  final double height;

  const DancheongBar({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌측 연장 ×1 — 가로로 늘리는 건 선이라 자연스러움
          Expanded(
            child: Image.asset(
              'assets/images/divider_line.png',
              fit: BoxFit.fill,
            ),
          ),
          // 중앙 장식 문양 — 비율 유지 (fitHeight)
          Image.asset(
            'assets/images/divider_center.png',
            fit: BoxFit.fitHeight,
            height: height,
          ),
          // 우측 연장 ×1
          Expanded(
            child: Image.asset(
              'assets/images/divider_line.png',
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}

/// 단청 테두리 장식 — Wraps child with dancheong bar on top
class DancheongBorder extends StatelessWidget {
  final Widget child;
  final double barHeight;
  final BorderRadius? borderRadius;

  const DancheongBorder({
    super.key,
    required this.child,
    this.barHeight = 24,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DancheongBar(height: barHeight),
          Flexible(child: child),
        ],
      ),
    );
  }
}
