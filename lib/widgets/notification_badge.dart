import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../models/dashboard_model.dart';

class NotificationBadge extends StatelessWidget {
  final List<UpcomingDeadline> deadlines;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.deadlines,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (deadlines.isEmpty) {
      return child;
    }

    // Get the most urgent deadline color
    Color badgeColor = _getMostUrgentColor();
    int count = deadlines.length;

    return Stack(
      children: [
        child,
        Positioned(
          right: -1,
          top: -1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.background,
                width: 1.5,
              ),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Color _getMostUrgentColor() {
    // Find the most urgent deadline
    Color mostUrgent = Colors.green; // Default to green (least urgent)

    for (final deadline in deadlines) {
      final urgencyColor = deadline.urgencyColor;

      // Red is most urgent
      if (urgencyColor == Colors.red) {
        return Colors.red;
      }

      // Orange is more urgent than green
      if (urgencyColor == Colors.orange && mostUrgent != Colors.red) {
        mostUrgent = Colors.orange;
      }
    }

    return mostUrgent;
  }
}
