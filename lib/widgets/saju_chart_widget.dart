import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SajuChartWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const SajuChartWidget({super.key, required this.chartData});

  // 천간 → 오행 매핑
  static const _stemElement = {
    '갑': 'wood', '을': 'wood',
    '병': 'fire', '정': 'fire',
    '무': 'earth', '기': 'earth',
    '경': 'metal', '신': 'metal',
    '임': 'water', '계': 'water',
  };

  // 천간 → 한자
  static const _stemHanja = {
    '갑': '甲', '을': '乙',
    '병': '丙', '정': '丁',
    '무': '戊', '기': '己',
    '경': '庚', '신': '辛',
    '임': '壬', '계': '癸',
  };

  // 지지 → 오행 매핑
  static const _branchElement = {
    '자': 'water', '축': 'earth',
    '인': 'wood', '묘': 'wood',
    '진': 'earth', '사': 'fire',
    '오': 'fire', '미': 'earth',
    '신': 'metal', '유': 'metal',
    '술': 'earth', '해': 'water',
  };

  // 지지 → 한자
  static const _branchHanja = {
    '자': '子', '축': '丑',
    '인': '寅', '묘': '卯',
    '진': '辰', '사': '巳',
    '오': '午', '미': '未',
    '신': '申', '유': '酉',
    '술': '戌', '해': '亥',
  };

  // 오행 한글 이름
  static const _elementKorean = {
    'wood': '목(木)', 'fire': '화(火)',
    'earth': '토(土)', 'metal': '금(金)',
    'water': '수(水)',
  };

  static Color _elementColor(String? element) {
    switch (element) {
      case 'wood':  return kWoodColor;
      case 'fire':  return kFireColor;
      case 'earth': return kEarthColor;
      case 'metal': return kMetalColor;
      case 'water': return kWaterColor;
      default:      return kDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final year  = chartData['yearPillar']  as Map<String, dynamic>?;
    final month = chartData['monthPillar'] as Map<String, dynamic>?;
    final day   = chartData['dayPillar']   as Map<String, dynamic>?;
    final hour  = chartData['hourPillar']  as Map<String, dynamic>?;

    if (year == null && month == null && day == null) {
      return const Center(child: Text('차트 데이터 없음', style: TextStyle(color: kTextMuted)));
    }

    final pillars = [hour, day, month, year];
    final labels  = ['시주', '일주', '월주', '연주'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kGlassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlassBorder),
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(labels[i],
                    style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            )),
          ),
          const SizedBox(height: 6),
          // 천간 (Heavenly Stems)
          Row(
            children: List.generate(4, (i) {
              final stem = _stemChar(pillars[i]);
              final element = _stemElement[stem];
              return Expanded(child: _pillarCell(stem, element, isStem: true));
            }),
          ),
          const SizedBox(height: 4),
          // 지지 (Earthly Branches)
          Row(
            children: List.generate(4, (i) {
              final branch = _branchChar(pillars[i]);
              final element = _branchElement[branch];
              return Expanded(child: _pillarCell(branch, element, isStem: false));
            }),
          ),
          const SizedBox(height: 4),
          // 지장간 (Hidden Stems)
          Row(
            children: List.generate(4, (i) {
              final hidden = _hiddenStems(pillars[i]);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kGlassBorder),
                  ),
                  child: Center(
                    child: hidden.isEmpty
                        ? const Text('', style: TextStyle(fontSize: 11))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: hidden.map((h) {
                              final elColor = _elementColor(_stemElement[h]);
                              return Text(
                                h,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: elColor.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _stemChar(Map<String, dynamic>? pillar) {
    if (pillar == null) return '';
    final stem = pillar['stem'] as Map<String, dynamic>?;
    return stem?['char'] as String? ?? '';
  }

  String _branchChar(Map<String, dynamic>? pillar) {
    if (pillar == null) return '';
    final branch = pillar['branch'] as Map<String, dynamic>?;
    return branch?['char'] as String? ?? '';
  }

  List<String> _hiddenStems(Map<String, dynamic>? pillar) {
    if (pillar == null) return [];
    final branch = pillar['branch'] as Map<String, dynamic>?;
    final list = branch?['hiddenStems'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((h) => (h as Map<String, dynamic>)['stem'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Widget _pillarCell(String text, String? element, {bool isStem = true}) {
    final color = _elementColor(element);
    final hanja = isStem ? _stemHanja[text] : _branchHanja[text];
    final elementName = element != null ? _elementKorean[element] : null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kGlassBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (hanja != null) ...[
              const SizedBox(height: 1),
              Text(
                hanja,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.6),
                ),
              ),
            ],
            if (elementName != null) ...[
              const SizedBox(height: 2),
              Text(
                elementName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
