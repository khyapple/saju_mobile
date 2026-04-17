import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FiveElementsWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const FiveElementsWidget({super.key, required this.chartData});

  static const _elements = [
    _ElementInfo('목', '木', kWoodColor,   ['성장', '창의', '인자']),
    _ElementInfo('화', '火', kFireColor,   ['열정', '명석', '예의']),
    _ElementInfo('토', '土', kEarthColor,  ['신뢰', '안정', '중용']),
    _ElementInfo('금', '金', kMetalColor,  ['의지', '결단', '정의']),
    _ElementInfo('수', '水', kWaterColor,  ['지혜', '유연', '감찰']),
  ];

  static const _keys = ['목', '화', '토', '금', '수'];

  @override
  Widget build(BuildContext context) {
    final distribution = chartData['fiveElements'] as Map<String, dynamic>?;
    if (distribution == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오행 분포',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGold),
        ),
        const SizedBox(height: 12),
        ...List.generate(_elements.length, (i) {
          final info = _elements[i];
          final count = ((distribution[_keys[i]] as num?)?.toInt()) ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ElementCard(info: info, count: count),
          );
        }),
      ],
    );
  }
}

class _ElementCard extends StatelessWidget {
  final _ElementInfo info;
  final int count;

  const _ElementCard({required this.info, required this.count});

  @override
  Widget build(BuildContext context) {
    final isWater = info.color == kWaterColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: info.color.withOpacity(isWater ? 0.45 : 0.28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
              children: [
                // 베이스 그라데이션
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.07),
                          Colors.white.withOpacity(0.02),
                          info.color.withOpacity(0.15),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // 대각선 광택
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.38, 0.42, 1.0],
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.02),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 콘텐츠
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // 한자
                      Text(
                        info.hanja,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isWater ? Colors.white : info.color,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 오른쪽: 이름 + 뱃지
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  info.korean,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 4),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$count개',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 4,
                              children: info.keywords.map((kw) => _Badge(
                                label: kw,
                                color: isWater ? Colors.white : info.color,
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ElementInfo {
  final String korean;
  final String hanja;
  final Color color;
  final List<String> keywords;

  const _ElementInfo(this.korean, this.hanja, this.color, this.keywords);
}
