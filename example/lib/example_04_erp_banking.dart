// super_navigation_sidebar · Example 04 — Banking / accounting ERP
// ─────────────────────────────────────────────────────────────────
// Goal: a realistic banking & accounting navigation that exercises the
// ERP-focused capabilities of the package:
//
//   • searchable: true   → built-in filter field; type to filter the (deep)
//                          tree, auto-expand matches, highlight the hit.
//   • favoritable: true  → star any destination; a "Quick Access" band is
//                          synthesized at the top (accountants pin Journal
//                          Entry, Trial Balance, Approvals…).
//   • NavNode.locked     → permission-gated screens (segregation of duties):
//                          dimmed, lock glyph, blocked navigation, tooltip.
//   • NavNode.status     → fiscal-period / ledger state dots
//                          (open · closed · locked · attention).
//   • NavBadge tones     → pending approvals (danger), live feeds (success).
//   • shortcut hints     → two-key chords with the keycap treatment.

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

List<NavSection<String>> _bankingSections({required int approvals}) => [
      NavSection(title: 'Overview', items: [
        NavNode(id: 'dashboard', label: 'Executive Dashboard',
            icon: Icons.dashboard_outlined, value: 'dashboard',
            shortcut: ['g', 'd']),
        NavNode(id: 'approvals', label: 'My Approvals',
            icon: Icons.fact_check_outlined, value: 'approvals',
            badge: NavBadge('$approvals', tone: NavBadgeTone.danger),
            shortcut: ['g', 'a']),
      ]),
      NavSection(title: 'General Ledger', items: [
        NavNode(id: 'glHub', label: 'General Ledger',
            icon: Icons.account_balance_outlined, children: [
          NavNode(id: 'periodsGroup', label: 'Fiscal Periods', children: [
            NavNode(id: 'fy25q3', label: 'FY2025 · Q3',
                icon: Icons.event_available_outlined, value: 'fy25q3',
                status: NavNodeStatus.open),
            NavNode(id: 'fy25q2', label: 'FY2025 · Q2',
                icon: Icons.event_busy_outlined, value: 'fy25q2',
                status: NavNodeStatus.closed),
            NavNode(id: 'fy25q1', label: 'FY2025 · Q1',
                icon: Icons.lock_clock_outlined, value: 'fy25q1',
                status: NavNodeStatus.locked),
          ]),
          NavNode(id: 'journalsGroup', label: 'Journals', children: [
            NavNode(id: 'journalEntry', label: 'Journal Entry',
                icon: Icons.edit_note_outlined, value: 'journalEntry',
                shortcut: ['g', 'j']),
            NavNode(id: 'recurringJe', label: 'Recurring Entries',
                icon: Icons.repeat, value: 'recurringJe'),
            NavNode(id: 'reconciliation', label: 'Reconciliation',
                icon: Icons.rule, value: 'reconciliation',
                status: NavNodeStatus.attention,
                badge: NavBadge('5', tone: NavBadgeTone.warning)),
          ]),
          NavNode(id: 'coaGroup', label: 'Chart of Accounts', children: [
            NavNode(id: 'accounts', label: 'Account List',
                icon: Icons.menu_book_outlined, value: 'accounts',
                shortcut: ['g', 'c']),
            NavNode(id: 'accountTree', label: 'Account Tree',
                icon: Icons.account_tree_outlined, value: 'accountTree'),
          ]),
        ]),
      ]),
      NavSection(title: 'Banking & Cash', items: [
        NavNode(id: 'treasuryHub', label: 'Treasury',
            icon: Icons.savings_outlined, children: [
          NavNode(id: 'cashGroup', label: 'Cash Management', children: [
            NavNode(id: 'positions', label: 'Cash Positions',
                icon: Icons.account_balance_wallet_outlined, value: 'positions',
                badge: NavBadge('Live', tone: NavBadgeTone.success)),
            NavNode(id: 'transfers', label: 'Fund Transfers',
                icon: Icons.swap_horiz, value: 'transfers',
                shortcut: ['g', 't']),
          ]),
          NavNode(id: 'paymentsGroup', label: 'Payments', children: [
            NavNode(id: 'outgoing', label: 'Outgoing Payments',
                icon: Icons.north_east, value: 'outgoing',
                badge: NavBadge('12', tone: NavBadgeTone.muted)),
            NavNode(id: 'wire', label: 'Wire / SWIFT',
                icon: Icons.bolt_outlined, value: 'wire',
                locked: true,
                lockMessage: 'Requires Treasury Approver role'),
          ]),
        ]),
        NavNode(id: 'arap', label: 'Payables & Receivables',
            icon: Icons.receipt_long_outlined, children: [
          NavNode(id: 'apGroup', label: 'Accounts Payable', children: [
            NavNode(id: 'vendorInvoices', label: 'Vendor Invoices',
                icon: Icons.description_outlined, value: 'vendorInvoices'),
            NavNode(id: 'payRun', label: 'Payment Run',
                icon: Icons.payments_outlined, value: 'payRun',
                locked: true,
                lockMessage: 'Requires AP Manager role'),
          ]),
          NavNode(id: 'arGroup', label: 'Accounts Receivable', children: [
            NavNode(id: 'custInvoices', label: 'Customer Invoices',
                icon: Icons.request_quote_outlined, value: 'custInvoices'),
            NavNode(id: 'collections', label: 'Collections',
                icon: Icons.event_repeat_outlined, value: 'collections',
                badge: NavBadge('8', tone: NavBadgeTone.warning)),
          ]),
        ]),
      ]),
      NavSection(title: 'Risk & Compliance', items: [
        NavNode(id: 'complianceHub', label: 'Compliance',
            icon: Icons.verified_user_outlined, children: [
          NavNode(id: 'amlGroup', label: 'AML / KYC', children: [
            NavNode(id: 'sanctions', label: 'Sanctions Screening',
                icon: Icons.gpp_maybe_outlined, value: 'sanctions',
                locked: true,
                lockMessage: 'Restricted — Compliance Officer only'),
            NavNode(id: 'sar', label: 'Suspicious Activity (SAR)',
                icon: Icons.flag_outlined, value: 'sar',
                locked: true, lockMessage: 'Restricted — Compliance Officer only'),
          ]),
          NavNode(id: 'auditGroup', label: 'Audit', children: [
            NavNode(id: 'auditLog', label: 'Audit Trail',
                icon: Icons.history_toggle_off, value: 'auditLog',
                status: NavNodeStatus.locked),
          ]),
        ]),
      ]),
      NavSection(title: 'Reports', items: [
        NavNode(id: 'reportsHub', label: 'Financial Reports',
            icon: Icons.insert_chart_outlined, children: [
          NavNode(id: 'finGroup', label: 'Statements', children: [
            NavNode(id: 'trialBalance', label: 'Trial Balance',
                icon: Icons.balance, value: 'trialBalance', shortcut: ['g', 'b']),
            NavNode(id: 'incomeStmt', label: 'Income Statement',
                icon: Icons.trending_up, value: 'incomeStmt'),
            NavNode(id: 'balanceSheet', label: 'Balance Sheet',
                icon: Icons.table_chart_outlined, value: 'balanceSheet'),
          ]),
        ]),
      ]),
    ];

class ErpBankingExample extends StatefulWidget {
  const ErpBankingExample({super.key});
  @override
  State<ErpBankingExample> createState() => _ErpBankingExampleState();
}

class _ErpBankingExampleState extends State<ErpBankingExample> {
  int _approvals = 7;
  String _screen = 'dashboard';

  late final NavigationSidebarController<String> _nav =
      NavigationSidebarController<String>(
    sections: _bankingSections(approvals: _approvals),
    active: 'dashboard',
    // Seed the Quick Access band with the accountant's daily screens.
    favorites: {'journalEntry', 'trialBalance', 'approvals'},
  );

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
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
            Text('04 · Banking / accounting ERP',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.fg1)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() => _approvals += 1);
                _nav.replaceSections(_bankingSections(approvals: _approvals));
              },
              icon: const Icon(Icons.add_alert_outlined, size: 16),
              label: Text('New approval ($_approvals)'),
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
              // ── the ERP capabilities, switched on ──
              searchable: true,
              searchHint: 'Search accounts, journals, reports…',
              favoritable: true,
              quickAccessTitle: 'Quick Access',
              shortcutMode: NavShortcutMode.onHover,
              header: (ctx, collapsed) => _Brand(collapsed: collapsed),
              onNavigate: (n) => setState(() => _screen = n.value!),
            ),
            Expanded(child: _Page(nav: _nav, screen: _screen)),
          ]),
        ),
      ]),
    );
  }
}

// ── Brand header ──────────────────────────────────────────────────
class _Brand extends StatelessWidget {
  final bool collapsed;
  const _Brand({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return SizedBox(
      height: 36,
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance, size: 15, color: Colors.white),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Text('Meridian Bank',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: s.fg1)),
        ],
      ]),
    );
  }
}

// ── Active page — breadcrumb + capability legend ──────────────────
class _Page extends StatelessWidget {
  final NavigationSidebarController<String> nav;
  final String screen;
  const _Page({required this.nav, required this.screen});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    final node = nav.node(screen);
    final crumb = [
      ...NavOps.ancestorsOf<String>(nav.sections, screen)
          .map((id) => nav.node(id)?.label ?? id),
      if (node != null) node.label,
    ].join('  ›  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(crumb.toUpperCase(),
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 10.5,
                letterSpacing: 1.4,
                color: s.fg4)),
        const SizedBox(height: 10),
        Text(node?.label ?? 'Workspace',
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.displayFont,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: s.fg1)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.border),
            borderRadius:
                BorderRadius.circular(s.radiusLg),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Try the ERP capabilities',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: s.fg1)),
            const SizedBox(height: 14),
            _legend(s, Icons.search, 'Search',
                'Type in the field above the tree — it filters every level, auto-expands matches and highlights the hit.'),
            _legend(s, Icons.star_rounded, 'Quick Access',
                'Hover any destination and tap the star. Starred screens surface in the band at the top. Journal Entry, Trial Balance & Approvals are pre-pinned.'),
            _legend(s, Icons.lock_outline, 'Locked screens',
                'Wire / SWIFT, Payment Run and the Compliance screens are permission-gated — dimmed, not clickable, with a reason tooltip on hover.'),
            _legend(s, Icons.circle, 'Status dots',
                'Fiscal periods carry state: Q3 open (green), Q2 closed (grey), Q1 locked (red), Reconciliation needs attention (amber).'),
          ]),
        ),
      ]),
    );
  }

  Widget _legend(NavigationSidebarThemeData s, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: NavigationSidebarThemeData.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: s.fg1)),
            const SizedBox(height: 2),
            Text(body,
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 12.5,
                    height: 1.5,
                    color: s.fg3)),
          ]),
        ),
      ]),
    );
  }
}
