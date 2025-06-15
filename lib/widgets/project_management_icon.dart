import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Custom project management icon widget that combines multiple elements
/// to create a comprehensive project management visual
class ProjectManagementIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool showBackground;
  final Color? backgroundColor;

  const ProjectManagementIcon({
    super.key,
    this.size = 60,
    this.color = Colors.white,
    this.showBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle if needed
          if (showBackground)
            Container(
              width: size * 1.4,
              height: size * 1.4,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),

          // Main chart/analytics icon (center-left)
          Positioned(
            left: size * 0.1,
            top: size * 0.3,
            child: Icon(
              FontAwesomeIcons.chartLine,
              size: size * 0.6,
              color: color,
            ),
          ),

          // Gear/settings icon (top-right)
          Positioned(
            right: size * 0.1,
            top: size * 0.1,
            child: Icon(
              FontAwesomeIcons.gear,
              size: size * 0.4,
              color: color,
            ),
          ),

          // Tasks/checklist icon (bottom-right)
          Positioned(
            right: size * 0.15,
            bottom: size * 0.15,
            child: Icon(
              FontAwesomeIcons.listCheck,
              size: size * 0.35,
              color: color,
            ),
          ),

          // Connection lines (simplified as small dots)
          Positioned(
            left: size * 0.45,
            top: size * 0.45,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.55,
            top: size * 0.35,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.65,
            top: size * 0.55,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified version using a single comprehensive icon
class SimpleProjectManagementIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SimpleProjectManagementIcon({
    super.key,
    this.size = 60,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main project/dashboard icon
        Icon(
          FontAwesomeIcons.diagramProject,
          size: size,
          color: color,
        ),

        // Small gear overlay to indicate management
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
            child: Icon(
              FontAwesomeIcons.gear,
              size: size * 0.25,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
