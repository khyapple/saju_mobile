import 'package:flutter/material.dart';

/// 단청 문양 장식 바 — Korean dancheong decorative bar (이미지 기반)
class DancheongBar extends StatelessWidget {
  final double height;

  const DancheongBar({super.key, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              'assets/images/dancheong_bar.png',
              fit: BoxFit.fill,
            ),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/dancheong_bar.png',
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
    this.barHeight = 16,
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
