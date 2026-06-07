import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 눌렀을 때 살짝 줄어드는 래퍼.
class Tappable extends StatefulWidget {
  const Tappable({super.key, required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 시그니처 컨테이너 — 파스텔(또는 흰) 채움 + 얇은 검정 아웃라인 + 둥근 모서리.
class OutlineCard extends StatelessWidget {
  const OutlineCard({
    super.key,
    required this.child,
    this.fill = AppColors.surface,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.outlineWidth = 1.6,
    this.onTap,
  });
  final Widget child;
  final Color fill;
  final EdgeInsets padding;
  final double radius;
  final double outlineWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.outline, width: outlineWidth),
      ),
      child: child,
    );
    return onTap == null ? card : Tappable(onTap: onTap, child: card);
  }
}

/// 1차 CTA — 검정 알약 (daydream).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gradient, // 호환용(미사용)
    this.enabled = true,
    this.height = 54,
    this.fill = AppColors.ink,
    this.fg = AppColors.inkOnDark,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final List<Color>? gradient;
  final bool enabled;
  final double height;
  final Color fill;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.outline, width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 19),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppType.sans(15, weight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아웃라인 버튼 (흰 바탕 + 검정 테두리).
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onTap, this.icon, this.height = 54});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: AppColors.outline, width: 1.6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.ink, size: 19),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppType.sans(15, weight: FontWeight.w800, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// 선택/필터 pill — 선택 시 파스텔 채움 + 검정 아웃라인.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.accent = AppColors.sky,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Color accent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 16, vertical: dense ? 7 : 9.5),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? AppColors.outline : AppColors.line,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(Icons.check_rounded, size: 14, color: AppColors.ink),
              ),
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: AppType.sans(dense ? 12.5 : 13.5,
                  weight: FontWeight.w700,
                  color: selected ? AppColors.ink : AppColors.inkSoft,
                  spacing: -0.1),
            ),
          ],
        ),
      ),
    );
  }
}

/// 작은 라운드 태그 — 파스텔 + 얇은 검정 아웃라인 + 차콜 텍스트.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.text, this.color = AppColors.sky, this.filled = true});
  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: filled ? color : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline, width: 1.2),
      ),
      child: Text(
        text,
        style: AppType.sans(11, weight: FontWeight.w800, color: AppColors.ink, spacing: 0.1),
      ),
    );
  }
}

/// 섹션 라벨 ("eyebrow").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppType.eyebrow);
}

/// 브랜드 워드마크 — "Яt" 말풍선 마크 + Russian Talk (앱 아이콘과 동일).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32, this.onDark = false, this.showWord = true});
  final double size;
  final bool onDark;
  final bool showWord;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.sky,
            borderRadius: BorderRadius.circular(size * 0.32),
            border: Border.all(color: AppColors.outline, width: 1.6),
          ),
          child: Text('МН',
              style: AppType.sans(size * 0.42, weight: FontWeight.w800, color: AppColors.ink, spacing: -1)),
        ),
        if (showWord) ...[
          SizedBox(width: size * 0.34),
          Text('Монгол Talk',
              style: AppType.serif(size * 0.6,
                  weight: FontWeight.w800,
                  color: onDark ? Colors.white : AppColors.ink,
                  spacing: -0.6)),
        ],
      ],
    );
  }
}
