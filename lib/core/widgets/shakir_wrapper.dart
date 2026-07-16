import 'package:flutter/material';
import '../theme/app_theme.dart';

class ShakirWrapper extends StatelessWidget {
  final Widget child;

  const ShakirWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual screen content
        child,

        // Transparent Watermark "SHAKIR" at 15-17% opacity
        IgnorePointer(
          child: Center(
            child: Transform.rotate(
              angle: -0.35, // Elegant rotation
              child: Opacity(
                opacity: 0.16, // Exactly 16% (between 15% and 17%)
                child: Text(
                  "SHAKIR",
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: AppTheme.goldPrimary,
                    decoration: TextDecoration.none,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
            ),
          ),
        ),

        // Elegant corner brandings in all four corners of the screen
        IgnorePointer(
          child: SafeArea(
            child: Stack(
              children: [
                // Top-Left Branding
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildCornerBadge(),
                ),
                // Top-Right Branding
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildCornerBadge(),
                ),
                // Bottom-Left Branding
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _buildCornerBadge(),
                ),
                // Bottom-Right Branding
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildCornerBadge(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.charcoalDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded, // Elegant star branding icon
            size: 8,
            color: AppTheme.goldPrimary,
          ),
          SizedBox(width: 2),
          Text(
            "Shakir",
            style: TextStyle(
              fontSize: 8,
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
