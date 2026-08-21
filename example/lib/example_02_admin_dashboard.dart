import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class AdminDashboardExample extends StatefulWidget {
  const AdminDashboardExample({super.key});

  @override
  State<AdminDashboardExample> createState() => _AdminDashboardExampleState();
}

class _AdminDashboardExampleState extends State<AdminDashboardExample> {
  int _pending = 9;
  late final NavigationSidebarController<String> _nav;

  List<NavSection<String>> _sections() => [
        NavSection<String>(
          title: 'Overview',
          items: [
            NavNode(
              id: 'dashboard',
              label: 'Dashboard',
              code: 'DB01',
              icon: Icons.dashboard_outlined,
              value: 'dashboard',
            ),
            NavNode(
              id: 'approvals',
              label: 'Approvals',
              code: 'AP01',
              icon: Icons.approval_outlined,
              badge: NavBadge('$_pending', tone: NavBadgeTone.danger),
              value: 'approvals',
            ),
          ],
        ),
        NavSection<String>(
          title: 'Finance',
          items: [
            NavNode(
              id: 'accounting',
              label: 'Accounting',
              icon: Icons.account_balance_outlined,
              children: [
                NavNode(
                  id: 'ledger_group',
                  label: 'General ledger',
                  children: [
                    NavNode(
                      id: 'chart',
                      label: 'Chart of accounts',
                      code: 'COA',
                      keywords: const ['accounts tree', 'ledger'],
                      icon: Icons.account_tree_outlined,
                      badge: const NavBadge('Live', tone: NavBadgeTone.success),
                      value: 'chart',
                    ),
                    NavNode(
                      id: 'journals',
                      label: 'Journal entries',
                      code: 'JE01',
                      keywords: const ['voucher', 'posting'],
                      icon: Icons.receipt_long_outlined,
                      value: 'journals',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        NavSection<String>(
          title: 'System',
          placement: NavSectionPlacement.footer,
          items: [
            NavNode(
              id: 'settings',
              label: 'Settings',
              icon: Icons.settings_outlined,
              value: 'settings',
            ),
          ],
        ),
      ];

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _sections(),
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _completeApproval() {
    if (_pending > 0) setState(() => _pending--);
    _nav.replaceSections(_sections());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = const NavSidebarBreakpoints().modeFor(constraints.maxWidth);
        final content = _DashboardContent(
          controller: _nav,
          pending: _pending,
          onCompleteApproval: _completeApproval,
          onOpenDrawer: _nav.openDrawer,
          showMenu: mode == NavSidebarMode.drawer,
        );

        if (mode == NavSidebarMode.drawer) {
          return Stack(
            children: [
              Positioned.fill(child: content),
              Positioned.fill(
                child: NavigationSidebar<String>(
                  controller: _nav,
                  mode: mode,
                  allowSearchView: true,
                  searchViewMode: NavigationSearchViewMode.sheet,
                  favoritable: true,
                  onNavigate: (_) => setState(() {}),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            NavigationSidebar<String>(
              controller: _nav,
              mode: mode,
              allowSearchView: true,
              searchViewMode: NavigationSearchViewMode.dialog,
              favoritable: true,
              showPaneToggle: true,
              onNavigate: (_) => setState(() {}),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final NavigationSidebarController<String> controller;
  final int pending;
  final VoidCallback onCompleteApproval;
  final VoidCallback onOpenDrawer;
  final bool showMenu;

  const _DashboardContent({
    required this.controller,
    required this.pending,
    required this.onCompleteApproval,
    required this.onOpenDrawer,
    required this.showMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    final active = controller.node(controller.active ?? '')?.label ?? 'Dashboard';
    return Material(
      color: theme.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                if (showMenu) ...[
                  IconButton(onPressed: onOpenDrawer, icon: const Icon(Icons.menu)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    active,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: theme.fg1,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: pending == 0 ? null : onCompleteApproval,
                  icon: const Icon(Icons.done),
                  label: const Text('Complete approval'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(label: 'Pending approvals', value: '$pending'),
                _Metric(label: 'Recent screens', value: '${controller.recents.length}'),
                _Metric(label: 'Favorites', value: '${controller.favorites.length}'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Version 3 keeps navigation state in the controller while the host owns its app scaffold.',
              style: TextStyle(color: theme.fg3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: theme.fg1, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: theme.fg3)),
        ],
      ),
    );
  }
}
