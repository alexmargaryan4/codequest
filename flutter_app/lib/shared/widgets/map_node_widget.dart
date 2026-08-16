import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../features/course_map/application/map_node_resolver.dart';

/// A single circular node on the course learning map representing exactly
/// one [MapNode] — one lesson or one mini-project, never a merged
/// cluster. Visually mirrors [TopicNodeWidget] (○ / ● / 🔒 style) but is
/// driven entirely by the node's own [MapNodeStatus], so a completed
/// lesson and its topic's still-locked (or freshly unlocked) mini-project
/// always render, and behave, independently of one another.
class MapNodeWidget extends StatelessWidget {
  const MapNodeWidget({
    required this.node,
    required this.accentColor,
    required this.onTap,
    super.key,
    this.size = 64,
  });

  final MapNode node;
  final Color accentColor;

  /// Null when the node should not react to taps at all (locked, or
  /// completed — completed nodes are rendered as history, not
  /// re-openable). The caller decides this by node status; this widget
  /// never infers "what happens next" on its own.
  final VoidCallback? onTap;

  final double size;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    late final Color fill;
    late final Color border;
    late final Widget icon;

    final bool isLocked = node.status == MapNodeStatus.locked;
    final bool isCompleted = node.status == MapNodeStatus.completed;
    final bool isAvailable =
        node.status == MapNodeStatus.available || node.status == MapNodeStatus.inProgress;
    final bool isMiniProject = node.type == MapNodeType.miniProject;

    if (isCompleted) {
      fill = accentColor;
      border = accentColor;
      icon = const Icon(Icons.check_rounded, color: Colors.white, size: 26);
    } else if (isAvailable) {
      fill = semantic.surfaceRaised;
      border = accentColor;
      icon = Icon(
        isMiniProject ? Icons.rocket_launch_rounded : _iconFor(node.topicIconName),
        color: accentColor,
        size: 24,
      );
    } else {
      fill = semantic.surfaceRaised;
      border = semantic.border;
      icon = Icon(Icons.lock_rounded, color: semantic.locked, size: 20);
    }

    final Widget dot = Container(
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
    );

    // Completed nodes stay visible on the path (they're history, not
    // dead weight) but onTap is null for them by construction — see
    // _MapBody._onNodeTap — so a tap on a completed node is a no-op:
    // it never re-opens the lesson/project or jumps to anything else.
    final Widget nodeColumn = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          dot,
          const SizedBox(height: 8),
          SizedBox(
            width: size + 24,
            child: Text(
              node.title,
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
      return nodeColumn
          .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
          .scale(
            duration: 1400.ms,
            curve: Curves.easeInOut,
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
          );
    }
    return nodeColumn;
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
