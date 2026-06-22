// super_navigation_sidebar · Example 02 — Admin dashboard with badges & shortcuts
// ────────────────────────────────────────────────────────────────────────────────
// Goal: showcase NavBadge tones, shortcut hints, deep-link via of(context),
//       and live badge updates via replaceSections.
//
//   • 4 sections, 15+ nodes (mirrors the ERP tree from the source demo)
//   • 3 badges: success ('Live'), danger ('9+'), muted ('12')
//   • 8 shortcut hints on leaves
//   • Active page shows breadcrumb + 3 "Quick nav" buttons that call
//     NavigationSidebarController.of<String>(context)?.navigate(id)
//   • "Simulate notification" button calls replaceSections to update a badge count

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

// ── Full ERP navigation tree ─────────────────────────────────────
List<NavSection<String>> _buildSections(int inboxCount) => <NavSection<String>>[
      NavSection(title: 'Overview', items: [
        NavNode(
            id: 'dashboard',
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            value: 'dashboard',
            shortcut: ['g', 'd']),
        NavNode(
            id: 'invDashboard',
            label: 'Inventory Dashboard',
            icon: Icons.qr_code_scanner,
            value: 'invDashboard',
            shortcut: ['g', 'i']),
      ]),
      NavSection(title: 'Finance', items: [
        NavNode(
            id: 'accountsHub',
            label: 'Accounts',
            icon: Icons.menu_book_outlined,
            children: [
              NavNode(id: 'coaGroup', label: 'Chart of Accounts', children: [
                NavNode(
                    id: 'accounts',
                    label: 'Chart of Accounts',
                    icon: Icons.menu_book_outlined,
                    value: 'accounts'),
                NavNode(
                    id: 'accountTree',
                    label: 'Account Tree',
                    icon: Icons.account_tree_outlined,
                    value: 'accountTree',
                    badge: NavBadge('3'),
                    shortcut: ['g', 't']),
              ]),
            ]),
        NavNode(
            id: 'ledgerHub',
            label: 'Ledger',
            icon: Icons.receipt_long_outlined,
            children: [
              NavNode(id: 'jeGroup', label: 'Journal Entries', children: [
                NavNode(
                    id: 'journals',
                    label: 'Journal Entries',
                    icon: Icons.receipt_long_outlined,
                    value: 'journals',
                    badge: NavBadge('Live', tone: NavBadgeTone.success),
                    shortcut: ['g', 'j']),
                NavNode(
                    id: 'createJournal',
                    label: 'Create Journal Entry',
                    icon: Icons.add,
                    value: 'createJournal'),
              ]),
            ]),
        NavNode(
            id: 'reportsHub',
            label: 'Reports',
            icon: Icons.description_outlined,
            children: [
              NavNode(id: 'finGroup', label: 'Financial', children: [
                NavNode(
                    id: 'trialBalance',
                    label: 'Trial Balance',
                    icon: Icons.menu_book_outlined,
                    value: 'trialBalance',
                    shortcut: ['g', 'b']),
                NavNode(
                    id: 'incomeStmt',
                    label: 'Income Statement',
                    icon: Icons.description_outlined,
                    value: 'incomeStmt'),
                NavNode(
                    id: 'balanceSheet',
                    label: 'Balance Sheet',
                    icon: Icons.description_outlined,
                    value: 'balanceSheet'),
              ]),
              NavNode(id: 'secGroup', label: 'Security', children: [
                NavNode(
                    id: 'auditLog',
                    label: 'Audit Log',
                    icon: Icons.lock_outline,
                    value: 'auditLog',
                    badge: NavBadge('12', tone: NavBadgeTone.muted)),
              ]),
            ]),
      ]),
      NavSection(title: 'Operations', items: [
        NavNode(
            id: 'storesHub',
            label: 'Inventory & Stores',
            icon: Icons.storefront_outlined,
            children: [
              NavNode(id: 'catalogGroup', label: 'Catalog', children: [
                NavNode(
                    id: 'products',
                    label: 'Products',
                    icon: Icons.qr_code_scanner,
                    value: 'products',
                    shortcut: ['g', 'p']),
              ]),
              NavNode(id: 'stockGroup', label: 'Stock Operations', children: [
                NavNode(
                    id: 'inventory',
                    label: 'Issue Inventory',
                    icon: Icons.qr_code_scanner,
                    value: 'inventory'),
                NavNode(
                    id: 'receive',
                    label: 'Receive Inventory',
                    icon: Icons.south,
                    value: 'receive'),
                NavNode(
                    id: 'stockTake',
                    label: 'Stock Take',
                    icon: Icons.check,
                    value: 'stockTake',
                    badge: NavBadge('New', tone: NavBadgeTone.success)),
              ]),
            ]),
      ]),
      NavSection(title: 'Administration', items: [
        NavNode(
            id: 'adminHub',
            label: 'Team & Access',
            icon: Icons.person_outline,
            children: [
              NavNode(id: 'usersGroup', label: 'Users', children: [
                NavNode(
                    id: 'users',
                    label: 'Users',
                    icon: Icons.person_outline,
                    value: 'users',
                    badge:
                        NavBadge('$inboxCount+', tone: NavBadgeTone.warning)),
                NavNode(
                    id: 'roles',
                    label: 'Roles & Permissions',
                    icon: Icons.settings_outlined,
                    value: 'roles'),
              ]),
            ]),
        NavNode(
            id: 'settingsHub',
            label: 'Settings',
            icon: Icons.settings_outlined,
            children: [
              NavNode(id: 'wsGroup', label: 'Workspace', children: [
                NavNode(
                    id: 'settingsGeneral',
                    label: 'General',
                    icon: Icons.settings_outlined,
                    value: 'settingsGeneral'),
              ]),
            ]),
      ]),
    ];

class AdminDashboardExample extends StatefulWidget {
  const AdminDashboardExample({super.key});
  @override
  State<AdminDashboardExample> createState() => _AdminDashboardExampleState();
}

class _AdminDashboardExampleState extends State<AdminDashboardExample> {
  int _inboxCount = 9;
  late NavigationSidebarController<String> _nav;

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _buildSections(_inboxCount),
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _simulateNotification() {
    setState(() => _inboxCount += 1);
    // ← hot-swap sections — the new badge count is immediately reflected
    //   in every view (expanded row pill, collapsed module dot, rail dot)
    _nav.replaceSections(_buildSections(_inboxCount));
  }

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: Column(children: [
        // mock app bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(bottom: BorderSide(color: s.border)),
          ),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: s.fg1),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Text('02 · Admin dashboard',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.fg1)),
            const Spacer(),
            // Simulate a notification arriving → badge count increments
            TextButton.icon(
              onPressed: _simulateNotification,
              icon: const Icon(Icons.notifications_outlined, size: 16),
              label: Text('Notify (${_inboxCount}+)'),
              style: TextButton.styleFrom(foregroundColor: s.fg2),
            ),
          ]),
        ),
        // body: sidebar + page
        Expanded(
          child: Row(children: [
            NavigationSidebar<String>(
              controller: _nav,
              mode: NavSidebarMode.expanded,
              showGuides: true,
              footer: (ctx, collapsed) =>
                  _ModeToggle(nav: _nav, collapsed: collapsed),
            ),
            Expanded(
              child: _ActivePage(nav: _nav),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Active page: breadcrumb + quick-nav buttons ───────────────────
class _ActivePage extends StatelessWidget {
  final NavigationSidebarController<String> nav;
  const _ActivePage({required this.nav});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    final activeId = nav.active ?? '';
    final node = nav.node(activeId);
    final ancestors = NavOps.ancestorsOf<String>(nav.sections, activeId)
        .map((id) => nav.node(id)?.label ?? id)
        .toList();
    final crumb = [...ancestors, if (node != null) node.label].join(' › ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(crumb.toUpperCase(),
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 10.5,
                letterSpacing: 1.6,
                color: s.fg4)),
        const SizedBox(height: 10),
        Text(node?.label ?? 'Workspace',
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.displayFont,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: s.fg1)),
        const SizedBox(height: 24),
        // ── Quick nav section ─────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.border),
            borderRadius:
                BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quick navigation',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: s.fg1)),
            const SizedBox(height: 6),
            Text(
              'These buttons call '
              'NavigationSidebarController.of<String>(context)'
              '?.navigate(id) — they work because this page '
              'is inside the NavigationSidebarScope.',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                  fontSize: 12.5,
                  color: s.fg3,
                  height: 1.5),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _QuickNavBtn('Dashboard', 'dashboard'),
              _QuickNavBtn('Journal Entries', 'journals'),
              _QuickNavBtn('Trial Balance', 'trialBalance'),
              _QuickNavBtn('Products', 'products'),
              _QuickNavBtn('Audit Log', 'auditLog'),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _QuickNavBtn extends StatelessWidget {
  final String label;
  final String targetId;
  const _QuickNavBtn(this.label, this.targetId);
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return GestureDetector(
      onTap: () =>
          // ← The key pattern: navigate from inside page content
          NavigationSidebarController.of<String>(context)?.navigate(targetId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: s.inputBg,
          border: Border.all(color: s.border),
          borderRadius:
              BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.fg1)),
      ),
    );
  }
}

// ── Expanded ↔ Rail toggle in footer ─────────────────────────────
class _ModeToggle extends StatelessWidget {
  final NavigationSidebarController<String> nav;
  final bool collapsed;
  const _ModeToggle({required this.nav, required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return GestureDetector(
      onTap: nav.toggleCollapsed,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.inputBg,
          border: Border.all(color: s.border),
          borderRadius:
              BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
              collapsed
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_left,
              size: 16,
              color: s.fg3),
          if (!collapsed) ...[
            const SizedBox(width: 6),
            Text('Collapse',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 12,
                    color: s.fg3)),
          ],
        ]),
      ),
    );
  }
}
