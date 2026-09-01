import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class KitchenSinkExample extends StatefulWidget {
  const KitchenSinkExample({super.key});

  @override
  State<KitchenSinkExample> createState() => _KitchenSinkExampleState();
}

class _KitchenSinkExampleState extends State<KitchenSinkExample> {
  late final SuperNavigationSidebarController<String> _nav;
  bool _rtl = false;
  bool _favorites = true;
  bool _aggregateBadges = true;
  bool _guides = true;

  static final _sections = <SuperNavSection<String>>[
    SuperNavSection<String>(
      title: 'Overview',
      items: [
        SuperNavNode(
          id: 'dashboard',
          label: Text('Dashboard'),
          code: 'DB01',
          keywords: const ['overview', 'home'],
          leadingIcon: Icon(Icons.dashboard_outlined),
          value: 'dashboard',
        ),
        SuperNavNode(
          id: 'approvals',
          label: Text('Approvals'),
          code: 'AP01',
          leadingIcon: Icon(Icons.approval_outlined),
          badge: const SuperNavBadge('12', tone: SuperNavBadgeTone.danger),
          value: 'approvals',
        ),
      ],
    ),
    SuperNavSection<String>(
      title: 'ERP',
      items: [
        SuperNavNode(
          id: 'finance',
          label: Text('Finance'),
          leadingIcon: Icon(Icons.account_balance_outlined),
          children: [
            SuperNavNode(
              id: 'gl',
              label: Text('General ledger'),
              children: [
                SuperNavNode(
                  id: 'journals',
                  label: Text('Journal entries'),
                  code: 'JE01',
                  keywords: const ['voucher', 'posting', 'قيد يومية'],
                  leadingIcon: Icon(Icons.receipt_long_outlined),
                  badge:
                      const SuperNavBadge('9', tone: SuperNavBadgeTone.warning),
                  value: 'journals',
                ),
                SuperNavNode(
                  id: 'period',
                  label: Text('Current fiscal period'),
                  code: 'FP01',
                  leadingIcon: Icon(Icons.calendar_month_outlined),
                  status: SuperNavNodeStatus.open,
                  value: 'period',
                ),
                SuperNavNode(
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
        SuperNavNode(
          id: 'inventory',
          label: Text('Inventory'),
          code: 'INV01',
          keywords: const ['stock', 'warehouse'],
          leadingIcon: Icon(Icons.inventory_2_outlined),
          value: 'inventory',
        ),
      ],
    ),
    SuperNavSection<String>(
      title: 'System',
      placement: SuperNavSectionPlacement.footer,
      items: [
        SuperNavNode(
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
    _nav = SuperNavigationSidebarController<String>(
      sections: _sections,
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _openSearch(BuildContext context, SuperNavigationSearchViewMode mode) {
    final l10n = SuperNavigationLocalization.of(context);
    showSuperNavigationSearchView<String>(
      context,
      controller: _nav,
      mode: mode,
      onPick: (id) {
        if (_nav.navigate(id)) setState(() {});
      },
      recentsLabel: l10n.recentsTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = _rtl ? const Locale('ar') : const Locale('en');
    final direction = _rtl ? TextDirection.rtl : TextDirection.ltr;
    return Localizations.override(
      context: context,
      locale: locale,
      delegates: SuperNavigationLocalization.localizationsDelegates,
      child: Directionality(
        textDirection: direction,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mode = const SuperNavSidebarBreakpoints().modeFor(
              constraints.maxWidth,
            );
            final searchMode = mode == SuperNavSidebarMode.drawer
                ? SuperNavigationSearchViewMode.sheet
                : SuperNavigationSearchViewMode.dialog;
            final sidebar = SuperNavigationSidebar<String>(
              controller: _nav,
              mode: mode,
              showGuides: _guides,
              favoritable: _favorites,
              aggregateBadges: _aggregateBadges,
              showPaneToggle: mode != SuperNavSidebarMode.drawer,
              allowSearchView: true,
              searchViewMode: searchMode,
              onNavigate: (_) => setState(() {}),
            );
            final page = _Workbench(
              controller: _nav,
              drawer: mode == SuperNavSidebarMode.drawer,
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
                  _openSearch(context, SuperNavigationSearchViewMode.dialog),
              onSheetSearch: () =>
                  _openSearch(context, SuperNavigationSearchViewMode.sheet),
            );

            if (mode == SuperNavSidebarMode.drawer) {
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
      ),
    );
  }
}

class _Workbench extends StatelessWidget {
  final SuperNavigationSidebarController<String> controller;
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
    final theme = SuperNavigationSidebarThemeData.of(context);
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
                    '3.2 Kitchen sink · $active',
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

String _plainExampleLabel<T>(SuperNavNode<T>? node,
    {required String fallback}) {
  if (node == null) return fallback;
  final label = node.label;
  if (label is Text) {
    return label.data ?? label.textSpan?.toPlainText() ?? node.id;
  }
  return node.keywords.isNotEmpty ? node.keywords.first : node.id;
}
