import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class NodeOnTapExample extends StatefulWidget {
  const NodeOnTapExample({super.key});

  @override
  State<NodeOnTapExample> createState() => _NodeOnTapExampleState();
}

class _NodeOnTapExampleState extends State<NodeOnTapExample> {
  late final SuperNavigationSidebarController<String> _nav;
  String _active = 'overview';
  String _lastAction = 'No node action yet';

  @override
  void initState() {
    super.initState();
    _nav = SuperNavigationSidebarController<String>(
      active: _active,
      sections: [
        SuperNavSection<String>(
          title: 'Actions',
          items: [
            SuperNavNode(
              id: 'overview',
              label: const Text('Overview'),
              leadingIcon: const Icon(Icons.space_dashboard_outlined),
              value: 'overview',
              onTap: (context) => _recordAction(context, 'Opened overview'),
            ),
            SuperNavNode(
              id: 'refresh',
              label: const Text('Refresh balances'),
              leadingIcon: const Icon(Icons.sync_outlined),
              code: 'RF01',
              keywords: const ['reload', 'balances'],
              value: 'refresh',
              onTap: (context) =>
                  _recordAction(context, 'Balance refresh queued'),
            ),
            SuperNavNode(
              id: 'review',
              label: const Text('Review approvals'),
              leadingIcon: const Icon(Icons.fact_check_outlined),
              badge: const SuperNavBadge('6', tone: SuperNavBadgeTone.warning),
              value: 'review',
              onTap: (context) =>
                  _recordAction(context, 'Approval queue opened'),
            ),
          ],
        ),
        SuperNavSection<String>(
          title: 'System',
          placement: SuperNavSectionPlacement.footer,
          items: [
            SuperNavNode(
              id: 'settings',
              label: const Text('Settings'),
              leadingIcon: const Icon(Icons.settings_outlined),
              value: 'settings',
              onTap: (context) =>
                  _recordAction(context, 'Settings action invoked'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _recordAction(BuildContext context, String message) {
    setState(() => _lastAction = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = SuperNavigationSidebarThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Row(
        children: [
          SuperNavigationSidebar<String>(
            controller: _nav,
            mode: SuperNavSidebarMode.expanded,
            showPaneToggle: true,
            allowSearchView: true,
            favoritable: true,
            onNavigate: (node) {
              setState(() => _active = node.value ?? node.id);
            },
          ),
          Expanded(
            child: _ActionPane(active: _active, lastAction: _lastAction),
          ),
        ],
      ),
    );
  }
}

class _ActionPane extends StatelessWidget {
  final String active;
  final String lastAction;

  const _ActionPane({required this.active, required this.lastAction});

  @override
  Widget build(BuildContext context) {
    final theme = SuperNavigationSidebarThemeData.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Node onTap actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: theme.fg1,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Active node: $active',
              style: TextStyle(color: theme.fg2, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Last action: $lastAction',
              style: TextStyle(color: theme.fg3, fontSize: 14),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surface,
                border: Border.all(color: theme.border),
                borderRadius: BorderRadius.circular(theme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Each destination owns an optional onTap callback. The '
                  'sidebar invokes it after successful navigation and before '
                  'the host onNavigate callback.',
                  style: TextStyle(color: theme.fg2, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
