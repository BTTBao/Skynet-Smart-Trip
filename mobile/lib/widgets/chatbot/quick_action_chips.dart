import 'package:flutter/material.dart';
import '../../models/chat_response.dart';

class QuickActionChips extends StatelessWidget {
  final List<QuickAction> actions;
  final Function(QuickAction) onTap;

  const QuickActionChips({
    super.key,
    required this.actions,
    required this.onTap,
  });

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'explore':
        return Icons.explore_outlined;
      case 'calendar':
        return Icons.calendar_month_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'weather':
        return Icons.wb_sunny_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'map':
        return Icons.map_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionChip(
            label: action.label,
            icon: _getIcon(action.icon),
            onTap: () => onTap(action),
          );
        },
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFF80ed99).withValues(alpha: 0.3)
              : const Color(0xFF80ed99).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF80ed99).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D6A4F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
