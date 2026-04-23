import 'package:flutter/material.dart';

/// 골드 구분선 위젯
/// 좌/우 끝에 장식(divider_end), 중앙 장식 문양(divider_center) 양쪽에 직선(divider_line) 4개씩 연장
/// — 이미지 비율 유지, 높이에 맞춰 크기 결정
class DancheongBar extends StatelessWidget {
  final double height;
  final String centerAsset;

  const DancheongBar({
    super.key,
    this.height = 24,
    this.centerAsset = 'assets/images/divider_center.png',
  });

  @override
  Widget build(BuildContext context) {
    final innerHeight = height * 0.8;
    Widget line() => Expanded(
          child: Image.asset('assets/images/divider_line.png', fit: BoxFit.fill),
        );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌측 끝 장식 — 비율 유지 (fitHeight), 80%로 축소
          Image.asset(
            'assets/images/divider_end.png',
            fit: BoxFit.fitHeight,
            height: innerHeight,
          ),
          // 좌측 연장 ×1 — 내부 Row에 80% 높이 부여 (stretch 상속 방지)
          Expanded(
            child: SizedBox(
              height: innerHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [line()],
              ),
            ),
          ),
          // 중앙 장식 문양 — 80%로 축소
          Image.asset(
            centerAsset,
            fit: BoxFit.fitHeight,
            height: innerHeight,
          ),
          // 우측 연장 ×1
          Expanded(
            child: SizedBox(
              height: innerHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [line()],
              ),
            ),
          ),
          // 우측 끝 장식 — 80%로 축소
          Image.asset(
            'assets/images/divider_end.png',
            fit: BoxFit.fitHeight,
            height: innerHeight,
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
