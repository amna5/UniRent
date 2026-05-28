import 'package:flutter/material.dart';
import 'theme.dart';

class UniRentLogo extends StatelessWidget {
  final double iconSize;
  final bool showText;
  final bool onDark;

  const UniRentLogo({
    super.key,
    this.iconSize = 56,
    this.showText = true,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: onDark ? Colors.white.withValues(alpha: 0.15) : AppTheme.primary,
                borderRadius: BorderRadius.circular(iconSize * 0.24),
                border: Border.all(
                  color: onDark ? Colors.white24 : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: iconSize * 0.56,
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: iconSize * 0.34,
                height: iconSize * 0.34,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onDark ? AppTheme.primary : Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.vpn_key_rounded,
                  color: Colors.white,
                  size: iconSize * 0.18,
                ),
              ),
            ),
          ],
        ),
        if (showText) ...[
          SizedBox(height: iconSize * 0.2),
          Text(
            'UniRent',
            style: TextStyle(
              color: Colors.white,
              fontSize: iconSize * 0.36,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class UniRentAppBarTitle extends StatelessWidget {
  const UniRentAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'UniRent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
