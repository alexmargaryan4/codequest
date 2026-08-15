import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Bottom-navigation shell wrapping Home / Learn / Leaderboard / Profile,
/// per the product spec's primary navigation structure.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const List<_NavDestination> _destinations = <_NavDestination>[
    _NavDestination(route: AppRoutes.home, icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Home'),
    _NavDestination(route: AppRoutes.learn, icon: Icons.school_rounded, outlineIcon: Icons.school_outlined, label: 'Learn'),
    _NavDestination(route: AppRoutes.leaderboard, icon: Icons.leaderboard_rounded, outlineIcon: Icons.leaderboard_outlined, label: 'Rank'),
    _NavDestination(route: AppRoutes.profile, icon: Icons.person_rounded, outlineIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) {
          context.go(_destinations[index].route);
        },
        destinations: _destinations
            .map(
              (_NavDestination d) => NavigationDestination(
                icon: Icon(d.outlineIcon),
                selectedIcon: Icon(d.icon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.route,
    required this.icon,
    required this.outlineIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData outlineIcon;
  final String label;
}
