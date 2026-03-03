import 'package:flutter/material.dart';
import 'package:viikshana/navigation/tv_menu_item.dart';
import 'package:viikshana/shared/tokens/viikshana_colors.dart';

enum TvMenuItemType {
  home,
  clips,
  notifications,
  watched,
  liked,
  playlists,
  saved,
  about,
  communityGuidelines,
  terms,
  contact,
}

extension TvMenuItemTypeExtension on TvMenuItemType {
  String get label {
    switch (this) {
      case TvMenuItemType.home:
        return 'Home';
      case TvMenuItemType.clips:
        return 'Clips';
      case TvMenuItemType.notifications:
        return 'Notifications';
      case TvMenuItemType.watched:
        return 'Watched';
      case TvMenuItemType.liked:
        return 'Liked';
      case TvMenuItemType.playlists:
        return 'Playlists';
      case TvMenuItemType.saved:
        return 'Saved';
      case TvMenuItemType.about:
        return 'About';
      case TvMenuItemType.communityGuidelines:
        return 'Community Guidelines';
      case TvMenuItemType.terms:
        return 'Terms';
      case TvMenuItemType.contact:
        return 'Contact';
    }
  }

  IconData get icon {
    switch (this) {
      case TvMenuItemType.home:
        return Icons.home;
      case TvMenuItemType.clips:
        return Icons.movie;
      case TvMenuItemType.notifications:
        return Icons.notifications;
      case TvMenuItemType.watched:
        return Icons.history;
      case TvMenuItemType.liked:
        return Icons.thumb_up;
      case TvMenuItemType.playlists:
        return Icons.playlist_play;
      case TvMenuItemType.saved:
        return Icons.bookmark;
      case TvMenuItemType.about:
        return Icons.info;
      case TvMenuItemType.communityGuidelines:
        return Icons.gavel;
      case TvMenuItemType.terms:
        return Icons.description;
      case TvMenuItemType.contact:
        return Icons.contact_support;
    }
  }
}

class TvShell extends StatefulWidget {
  const TvShell({super.key});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  TvMenuItemType _selected = TvMenuItemType.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViikshanaColors.backgroundDark,
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: ViikshanaColors.surfaceDark,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView(
          padding: const EdgeInsets.only(top: 48, bottom: 24),
          children: TvMenuItemType.values
              .map(
                (item) => TvMenuItem(
                  key: ValueKey(item),
                  label: item.label,
                  icon: item.icon,
                  selected: _selected == item,
                  onTap: () => setState(() => _selected = item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Text(
        _selected.label,
        style: const TextStyle(
          fontSize: 32,
          color: ViikshanaColors.onSurfaceDark,
        ),
      ),
    );
  }
}
