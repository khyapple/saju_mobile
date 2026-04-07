import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 시머 로딩 효과 (스켈레톤 로딩)
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-0.5 + 2.0 * _ctrl.value, 0),
              colors: const [
                kLightPanel,
                kMediumPanel,
                kLightPanel,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 프로필 카드 스켈레톤
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kGlassFill,
        border: Border.all(color: kGlassBorder, width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading(width: 40, height: 40, borderRadius: 20),
              ShimmerLoading(width: 56, height: 20, borderRadius: 10),
            ],
          ),
          Spacer(),
          ShimmerLoading(width: 80, height: 18),
          SizedBox(height: 8),
          ShimmerLoading(width: 100, height: 12),
          SizedBox(height: 4),
          ShimmerLoading(width: 40, height: 12),
        ],
      ),
    );
  }
}
