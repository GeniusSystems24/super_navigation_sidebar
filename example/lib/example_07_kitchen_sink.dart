import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class KitchenSinkExample extends StatefulWidget {
  const KitchenSinkExample({super.key});

  @override
  State<KitchenSinkExample> createState() => _KitchenSinkExampleState();
}

class _KitchenSinkExampleState extends State<KitchenSinkExample> {
  late final NavigationSidebarController<String> _nav;
  bool _rtl = false;
  bool _favorites = true;
  bool _aggregateBadges = true;
  bool _guides = true;

  static final _sections = <NavSection<String>>[
    NavSection<String>(
      title: 'Overview',
      items: [
        NavNode(
          id: 'dashboard',
          label: Text('Dashboard'),
          code: 'DB01',
          keywords: const ['overview', 'home'],
          leadingIcon: Icon(Icons.dashboard_outlined),
          value: 'dashboard',
        ),
        NavNode(
          id: 'approvals',
          label: Text('Approvals'),
          code: 'AP01',
          leadingIcon: Icon(Icons.approval_outlined),
          badge: const NavBadge('12', tone: NavBadgeTone.danger),
          value: 'approvals',
        ),
      ],
    ),
    NavSection<String>(
      title: 'ERP',
      items: [
        NavNode(
          id: 'finance',
          label: Text('Finance'),
          leadingIcon: Icon(Icons.account_balance_outlined),
          children: [
            NavNode(
              id: 'gl',
              label: Text('General ledger'),
              children: [
                NavNode(
                  id: 'journals',
                  label: Text('Journal entries'),
                  code: 'JE01',
                  keywords: const ['voucher', 'posting', 'قيد يومية'],
                  leadingIcon: Icon(Icons.receipt_long_outlined),
                  badge: const NavBadge('9', tone: NavBadgeTone.warning),
                  value: 'journals',
                ),
                NavNode(
                  id: 'period',
                  label: Text('Current fiscal period'),
                  code: 'FP01',
                  leadingIcon: Icon(Icons.calendar_month_outlined),
                  status: NavNodeStatus.open,
                  value: 'period',
                ),
                NavNode(
                  id: 'restricted',
                  label: Text('Year-end close'),
                  leadingIcon: Icon(Icons.lock_outline),
                  locked: true,
                  lockMessage: 'Requires Controller role',
                  value: 'restricted',
                ),
              ],
            ),
          ],
        ),
        NavNode(
          id: 'inventory',
          label: Text('Inventory'),
          code: 'INV01',
          keywords: const ['stock', 'warehouse'],
          leadingIcon: Icon(Icons.inventory_2_outlined),
          value: 'inventory',
        ),
      ],
    ),
    NavSection<String>(
      title: 'System',
      placement: NavSectionPlacement.footer,
      items: [
        NavNode(
          id: 'settings',
          label: Text('Settings'),
          code: 'SET01',
          leadingIcon: Icon(Icons.settings_outlined),
          value: 'settings',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _sections,
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _openSearch(BuildContext context, NavigationSearchViewMode mode) {
    showNavigationSearchView<String>(
      context,
      controller: _nav,
      mode: mode,
      onPick: (id) {
        if (_nav.navigate(id)) setState(() {});
      },
      recentsLabel: _rtl ? 'الأخيرة' : 'Recent',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mode = const NavSidebarBreakpoints().modeFor(
            constraints.maxWidth,
          );
          final searchMode = mode == NavSidebarMode.drawer
              ? NavigationSearchViewMode.sheet
              : NavigationSearchViewMode.dialog;
          final sidebar = NavigationSidebar<String>(
            controller: _nav,
            mode: mode,
            showGuides: _guides,
            favoritable: _favorites,
            aggregateBadges: _aggregateBadges,
            showPaneToggle: mode != NavSidebarMode.drawer,
            allowSearchView: true,
            searchViewMode: searchMode,
            localizations: _rtl
                ? NavigationSidebarLocalizations.arabic
                : const NavigationSidebarLocalizations(),
            onNavigate: (_) => setState(() {}),
          );
          final page = _Workbench(
            controller: _nav,
            drawer: mode == NavSidebarMode.drawer,
            onOpenDrawer: _nav.openDrawer,
            rtl: _rtl,
            favorites: _favorites,
            aggregateBadges: _aggregateBadges,
            guides: _guides,
            onRtl: (v) => setState(() => _rtl = v),
            onFavorites: (v) => setState(() => _favorites = v),
            onAggregate: (v) => setState(() => _aggregateBadges = v),
            onGuides: (v) => setState(() => _guides = v),
            onDialogSearch: () =>
                _openSearch(context, NavigationSearchViewMode.dialog),
            onSheetSearch: () =>
                _openSearch(context, NavigationSearchViewMode.sheet),
          );

          if (mode == NavSidebarMode.drawer) {
            return Stack(
              children: [
                Positioned.fill(child: page),
                Positioned.fill(child: sidebar),
              ],
            );
          }
          return Row(
            children: [
              sidebar,
              Expanded(child: page),
            ],
          );
        },
      ),
    );
  }
}

class _Workbench extends StatelessWidget {
  final NavigationSidebarController<String> controller;
  final bool drawer;
  final VoidCallback onOpenDrawer;
  final bool rtl;
  final bool favorites;
  final bool aggregateBadges;
  final bool guides;
  final ValueChanged<bool> onRtl;
  final ValueChanged<bool> onFavorites;
  final ValueChanged<bool> onAggregate;
  final ValueChanged<bool> onGuides;
  final VoidCallback onDialogSearch;
  final VoidCallback onSheetSearch;

  const _Workbench({
    required this.controller,
    required this.drawer,
    required this.onOpenDrawer,
    required this.rtl,
    required this.favorites,
    required this.aggregateBadges,
    required this.guides,
    required this.onRtl,
    required this.onFavorites,
    required this.onAggregate,
    required this.onGuides,
    required this.onDialogSearch,
    required this.onSheetSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    final active = _plainExampleLabel(
      controller.node(controller.active ?? ''),
      fallback: 'Dashboard',
    );
    return Material(
      color: theme.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                if (drawer)
                  IconButton(
                    onPressed: onOpenDrawer,
                    icon: const Icon(Icons.menu),
                  ),
                Expanded(
                  child: Text(
                    '3.0 Kitchen sink · $active',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: theme.fg1,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: onDialogSearch,
                  child: const Text('Search dialog'),
                ),
                OutlinedButton(
                  onPressed: onSheetSearch,
                  child: const Text('Search sheet'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: rtl,
              onChanged: onRtl,
              title: const Text('RTL + Arabic localization'),
            ),
            SwitchListTile(
              value: favorites,
              onChanged: onFavorites,
              title: const Text('Quick Access favorites'),
            ),
            SwitchListTile(
              value: aggregateBadges,
              onChanged: onAggregate,
              title: const Text('Aggregate numeric badges'),
            ),
            SwitchListTile(
              value: guides,
              onChanged: onGuides,
              title: const Text('Tree connector guides'),
            ),
            const SizedBox(height: 18),
            Text(
              'Search accepts labels, screen codes, and hidden keywords. Try JE01, voucher, warehouse, or قيد.',
              style: TextStyle(color: theme.fg3, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Recent: ${controller.recents.join(' · ')}',
              style: TextStyle(color: theme.fg2),
            ),
          ],
        ),
      ),
    );
  }
}

String _plainExampleLabel<T>(NavNode<T>? node, {required String fallback}) {
  if (node == null) return fallback;
  final label = node.label;
  if (label is Text) {
    return label.data ?? label.textSpan?.toPlainText() ?? node.id;
  }
  return node.keywords.isNotEmpty ? node.keywords.first : node.id;
}
