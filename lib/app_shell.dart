import 'package:flutter/material.dart';
import 'package:private_statistics/features/categories/presentation/categories_screen.dart';
import 'package:private_statistics/features/events/presentation/calendar_screen.dart';
import 'package:private_statistics/features/events/presentation/events_screen.dart';
import 'package:private_statistics/features/settings/presentation/settings_screen.dart';
import 'package:private_statistics/features/statistics/presentation/statistics_screen.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Root scaffold that hosts the bottom [NavigationBar] and the four main
/// feature screens (Calendar, Events, Statistics, Categories).
class AppShell extends StatefulWidget {
  /// Creates the [AppShell].
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    CalendarScreen(),
    EventsScreen(),
    StatisticsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_outlined),
            selectedIcon: const Icon(Icons.list),
            label: l10n.navEvents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: l10n.navCategories,
          ),
        ],
      ),
    );
  }
}
