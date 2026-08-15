import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course.dart';

/// A single circular node on the course learning map (○ / ● / 🔒), matching
/// the product spec's visual reference. Completed nodes are filled with
/// [accentColor] and show a check; the current available node pulses
/// gently; locked nodes are dimmed with a lock glyph.
class TopicNodeWidget extends StatelessWidget {
  const TopicNodeWidget({
    required this.topic,
    required this.accentColor,
    required this.onTap,
    super.key,
    this.size = 64,
  });

  final TopicNode topic;
  final Color accentColor;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    late final Color fill;
    late final Color border;
    late final Widget icon;
    final bool isLocked = topic.status == TopicNodeStatus.locked;
    final bool isCompleted = topic.status == TopicNodeStatus.completed;
    final bool isAvailable =
        topic.status == TopicNodeStatus.available || topic.status == TopicNodeStatus.inProgress;

    if (isCompleted) {
      fill = accentColor;
      border = accentColor;
      icon = const Icon(Icons.check_rounded, color: Colors.white, size: 26);
    } else if (isAvailable) {
      fill = semantic.surfaceRaised;
      border = accentColor;
      icon = Icon(_iconFor(topic.iconName), color: accentColor, size: 24);
    } else {
      fill = semantic.surfaceRaised;
      border = semantic.border;
      icon = Icon(Icons.lock_rounded, color: semantic.locked, size: 20);
    }

    final Widget node = GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: isAvailable ? 2.5 : 2),
              boxShadow: isAvailable
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size + 24,
            child: Text(
              topic.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: isLocked ? semantic.textMuted : null,
                fontWeight: isAvailable ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (isAvailable) {
      return node
          .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
          .scale(
            duration: 1400.ms,
            curve: Curves.easeInOut,
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
          );
    }
    return node;
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'variable':
        return Icons.data_object_rounded;
      case 'text':
        return Icons.text_fields_rounded;
      case 'number':
        return Icons.pin_rounded;
      case 'condition':
        return Icons.alt_route_rounded;
      case 'loop':
        return Icons.autorenew_rounded;
      case 'function':
        return Icons.functions_rounded;
      case 'list':
        return Icons.list_rounded;
      case 'dict':
        return Icons.data_array_rounded;
      case 'oop':
        return Icons.hub_rounded;
      case 'project':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.code_rounded;
    }
  }
}

/// A short connecting segment drawn between two [TopicNodeWidget]s to
/// form the winding vertical path shown in the product spec's map
/// reference.
class NodeConnector extends StatelessWidget {
  const NodeConnector({required this.completed, super.key, this.height = 32});

  final bool completed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: completed ? AppColors.accentIndigo : semantic.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
