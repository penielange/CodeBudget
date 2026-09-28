import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/forecasts')) return 1;
    if (loc.startsWith('/history')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(loc),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/forecasts');
              break;
            case 2:
              context.go('/history');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Prévisions'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Réglages'),
        ],
      ),
    );
  }
}
