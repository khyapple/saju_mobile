import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FiveElementsWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const FiveElementsWidget({super.key, required this.chartData});

  static const _elements = [
    ('목', '木', kWoodColor),
    ('화', '火', kFireColor),
    ('토', '土', kEarthColor),
    ('금', '金', kMetalColor),
    ('수', '水', kWaterColor),
  ];

  // API returns Korean keys matching FiveElementsBalance
  static const _keys = ['목', '화', '토', '금', '수'];

  @override
  Widget build(BuildContext context) {
    final distribution = chartData['fiveElements'] as Map<String, dynamic>?;
    if (distribution == null) return const SizedBox.shrink();

    final total = _keys.fold<int>(
      0,
      (sum, key) => sum + ((distribution[key] as num?)?.toInt() ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kGlassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오행 분포',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kGold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_elements.length, (i) {
            final (kor, hanja, color) = _elements[i];
            final count = ((distribution[_keys[i]] as num?)?.toInt()) ?? 0;
            final ratio = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$kor $hanja',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: const Color(0x14FFFFFF),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
