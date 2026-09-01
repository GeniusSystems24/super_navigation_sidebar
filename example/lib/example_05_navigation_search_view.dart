import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class NavigationSearchViewExample extends StatefulWidget {
  const NavigationSearchViewExample({super.key});

  @override
  State<NavigationSearchViewExample> createState() =>
      _NavigationSearchViewExampleState();
}

class _NavigationSearchViewExampleState
    extends State<NavigationSearchViewExample> {
  late final SuperNavigationSidebarController<String> _nav;

  static final _sections = <SuperNavSection<String>>[
    SuperNavSection<String>(
      title: 'Workspace',
      items: [
        SuperNavNode(
          id: 'dashboard',
          label: Text('Dashboard'),
          code: 'DB01',
          keywords: const ['home', 'overview'],
          leadingIcon: Icon(Icons.dashboard_outlined),
          value: 'dashboard',
        ),
        SuperNavNode(
          id: 'finance',
          label: Text('Finance'),
          leadingIcon: Icon(Icons.account_balance_outlined),
          children: [
            SuperNavNode(
              id: 'ledger',
              label: Text('General ledger'),
              children: [
                SuperNavNode(
                  id: 'accounts',
                  label: Text('Chart of accounts'),
                  code: 'COA',
                  keywords: const ['account tree', 'ledger'],
                  leadingIcon: Icon(Icons.account_tree_outlined),
                  value: 'accounts',
                ),
                SuperNavNode(
                  id: 'journals',
                  label: Text('Journal entries'),
                  code: 'JE01',
                  keywords: const ['voucher', 'posting', 'قيد'],
                  leadingIcon: Icon(Icons.receipt_long_outlined),
                  badge:
                      const SuperNavBadge('8', tone: SuperNavBadgeTone.warning),
                  value: 'journals',
                ),
              ],
            ),
          ],
        ),
        SuperNavNode(
          id: 'inventory',
          label: Text('Inventory'),
          code: 'INV01',
          keywords: const ['stock', 'products'],
          leadingIcon: Icon(Icons.inventory_2_outlined),
          value: 'inventory',
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

  void _pick(SuperNavNodeId id) {
    if (_nav.navigate(id)) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = SuperNavigationSidebarThemeData.of(context);
    return Material(
      color: theme.bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (wide)
                  SuperNavigationSidebar<String>(
                    controller: _nav,
                    mode: SuperNavSidebarMode.expanded,
                    allowSearchView: true,
                    searchViewMode: SuperNavigationSearchViewMode.dialog,
                    onNavigate: (_) => setState(() {}),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'SuperNavigationSearchView',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: theme.fg1,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The same reusable search surface can be embedded, opened as a dialog, or opened as a modal bottom sheet.',
                        style: TextStyle(color: theme.fg3, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                showSuperNavigationSearchView<String>(
                              context,
                              controller: _nav,
                              mode: SuperNavigationSearchViewMode.dialog,
                              onPick: _pick,
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open dialog'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                showSuperNavigationSearchView<String>(
                              context,
                              controller: _nav,
                              mode: SuperNavigationSearchViewMode.sheet,
                              onPick: _pick,
                            ),
                            icon: const Icon(Icons.vertical_align_top),
                            label: const Text('Open sheet'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Active: ${_plainExampleLabel(_nav.node(_nav.active ?? ''), fallback: 'None')}',
                        style: TextStyle(
                          color: theme.fg2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 520,
                        child: SuperNavigationSearchView<String>(
                          controller: _nav,
                          autofocus: false,
                          closeOnPick: false,
                          onPick: _pick,
                          onClose: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
