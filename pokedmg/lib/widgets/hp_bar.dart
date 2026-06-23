// lib/widgets/hp_bar.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HpBar extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final bool showLabel;

  const HpBar({
    super.key,
    required this.currentHp,
    required this.maxHp,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (currentHp / maxHp).clamp(0.0, 1.0);
    final color = AppTheme.hpColor(percent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$currentHp / $maxHp',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                color: AppTheme.divider,
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                widthFactor: percent,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
