import 'package:flutter/material.dart';
import 'package:viikshana/screens/home/home_screen.dart';
import 'package:viikshana/screens/clips/clips_screen.dart';
import 'package:viikshana/screens/upload/upload_screen.dart';
import 'package:viikshana/screens/search/search_screen.dart';
import 'package:viikshana/screens/account/account_screen.dart';

enum MobileTab { home, clips, upload, search, account }

extension MobileTabExtension on MobileTab {
  int get index => MobileTab.values.indexOf(this);
  String get label {
    switch (this) {
      case MobileTab.home:
        return 'Home';
      case MobileTab.clips:
        return 'Clips';
      case MobileTab.upload:
        return 'Upload';
      case MobileTab.search:
        return 'Search';
      case MobileTab.account:
        return 'Account';
    }
  }
  IconData get icon {
    switch (this) {
      case MobileTab.home:
        return Icons.home_outlined;
      case MobileTab.clips:
        return Icons.movie_outlined;
      case MobileTab.upload:
        return Icons.add_circle_outline;
      case MobileTab.search:
        return Icons.search;
      case MobileTab.account:
        return Icons.person_outline;
    }
  }
  IconData get selectedIcon {
    switch (this) {
      case MobileTab.home:
        return Icons.home;
      case MobileTab.clips:
        return Icons.movie;
      case MobileTab.upload:
        return Icons.add_circle;
      case MobileTab.search:
        return Icons.search;
      case MobileTab.account:
        return Icons.person;
    }
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// Stub: set to true when in full-screen playback to hide bottom nav.
  static bool get _hideBottomNavForFullScreen => false;

  static final List<Widget> _tabRoots = [
    const HomeScreen(),
    const ClipsScreen(),
    const UploadScreen(),
    const SearchScreen(),
    const AccountScreen(),
  ];

  Widget _buildNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => _tabRoots[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _buildNavigator),
      ),
      bottomNavigationBar: _hideBottomNavForFullScreen
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() => _currentIndex = index);
              },
              destinations: MobileTab.values
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.selectedIcon),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
