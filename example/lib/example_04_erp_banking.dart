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
//   • SuperNavNode.locked     → permission-gated screens (segregation of duties):
//                          dimmed, lock glyph, blocked navigation, tooltip.
//   • SuperNavNode.status     → fiscal-period / ledger state dots
//                          (open · closed · locked · attention).
//   • SuperNavBadge tones     → pending approvals (danger), live feeds (success).
//   • navigation metadata     → screen codes and searchable labels.

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

List<SuperNavSection<String>> _bankingSections({required int approvals}) => [
      SuperNavSection(
        title: 'Overview',
        items: [
          SuperNavNode(
            id: 'dashboard',
            label: Text('Executive Dashboard'),
            leadingIcon: Icon(Icons.dashboard_outlined),
            value: 'dashboard',
          ),
          SuperNavNode(
            id: 'approvals',
            label: Text('My Approvals'),
            leadingIcon: Icon(Icons.fact_check_outlined),
            value: 'approvals',
            badge: SuperNavBadge('$approvals', tone: SuperNavBadgeTone.danger),
          ),
        ],
      ),
      SuperNavSection(
        title: 'General Ledger',
        items: [
          SuperNavNode(
            id: 'glHub',
            label: Text('General Ledger'),
            leadingIcon: Icon(Icons.account_balance_outlined),
            children: [
              SuperNavNode(
                id: 'periodsGroup',
                label: Text('Fiscal Periods'),
                children: [
                  SuperNavNode(
                    id: 'fy25q3',
                    label: Text('FY2025 · Q3'),
                    leadingIcon: Icon(Icons.event_available_outlined),
                    value: 'fy25q3',
                    status: SuperNavNodeStatus.open,
                  ),
                  SuperNavNode(
                    id: 'fy25q2',
                    label: Text('FY2025 · Q2'),
                    leadingIcon: Icon(Icons.event_busy_outlined),
                    value: 'fy25q2',
                    status: SuperNavNodeStatus.closed,
                  ),
                  SuperNavNode(
                    id: 'fy25q1',
                    label: Text('FY2025 · Q1'),
                    leadingIcon: Icon(Icons.lock_clock_outlined),
                    value: 'fy25q1',
                    status: SuperNavNodeStatus.locked,
                  ),
                ],
              ),
              SuperNavNode(
                id: 'journalsGroup',
                label: Text('Journals'),
                children: [
                  SuperNavNode(
                    id: 'journalEntry',
                    label: Text('Journal Entry'),
                    leadingIcon: Icon(Icons.edit_note_outlined),
                    value: 'journalEntry',
                  ),
                  SuperNavNode(
                    id: 'recurringJe',
                    label: Text('Recurring Entries'),
                    leadingIcon: Icon(Icons.repeat),
                    value: 'recurringJe',
                  ),
                  SuperNavNode(
                    id: 'reconciliation',
                    label: Text('Reconciliation'),
                    leadingIcon: Icon(Icons.rule),
                    value: 'reconciliation',
                    status: SuperNavNodeStatus.attention,
                    badge: SuperNavBadge('5', tone: SuperNavBadgeTone.warning),
                  ),
                ],
              ),
              SuperNavNode(
                id: 'coaGroup',
                label: Text('Chart of Accounts'),
                children: [
                  SuperNavNode(
                    id: 'accounts',
                    label: Text('Account List'),
                    leadingIcon: Icon(Icons.menu_book_outlined),
                    value: 'accounts',
                  ),
                  SuperNavNode(
                    id: 'accountTree',
                    label: Text('Account Tree'),
                    leadingIcon: Icon(Icons.account_tree_outlined),
                    value: 'accountTree',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      SuperNavSection(
        title: 'Banking & Cash',
        items: [
          SuperNavNode(
            id: 'treasuryHub',
            label: Text('Treasury'),
            leadingIcon: Icon(Icons.savings_outlined),
            children: [
              SuperNavNode(
                id: 'cashGroup',
                label: Text('Cash Management'),
                children: [
                  SuperNavNode(
                    id: 'positions',
                    label: Text('Cash Positions'),
                    leadingIcon: Icon(Icons.account_balance_wallet_outlined),
                    value: 'positions',
                    badge:
                        SuperNavBadge('Live', tone: SuperNavBadgeTone.success),
                  ),
                  SuperNavNode(
                    id: 'transfers',
                    label: Text('Fund Transfers'),
                    leadingIcon: Icon(Icons.swap_horiz),
                    value: 'transfers',
                  ),
                ],
              ),
              SuperNavNode(
                id: 'paymentsGroup',
                label: Text('Payments'),
                children: [
                  SuperNavNode(
                    id: 'outgoing',
                    label: Text('Outgoing Payments'),
                    leadingIcon: Icon(Icons.north_east),
                    value: 'outgoing',
                    badge: SuperNavBadge('12', tone: SuperNavBadgeTone.muted),
                  ),
                  SuperNavNode(
                    id: 'wire',
                    label: Text('Wire / SWIFT'),
                    leadingIcon: Icon(Icons.bolt_outlined),
                    value: 'wire',
                    locked: true,
                    lockMessage: 'Requires Treasury Approver role',
                  ),
                ],
              ),
            ],
          ),
          SuperNavNode(
            id: 'arap',
            label: Text('Payables & Receivables'),
            leadingIcon: Icon(Icons.receipt_long_outlined),
            children: [
              SuperNavNode(
                id: 'apGroup',
                label: Text('Accounts Payable'),
                children: [
                  SuperNavNode(
                    id: 'vendorInvoices',
                    label: Text('Vendor Invoices'),
                    leadingIcon: Icon(Icons.description_outlined),
                    value: 'vendorInvoices',
                  ),
                  SuperNavNode(
                    id: 'payRun',
                    label: Text('Payment Run'),
                    leadingIcon: Icon(Icons.payments_outlined),
                    value: 'payRun',
                    locked: true,
                    lockMessage: 'Requires AP Manager role',
                  ),
                ],
              ),
              SuperNavNode(
                id: 'arGroup',
                label: Text('Accounts Receivable'),
                children: [
                  SuperNavNode(
                    id: 'custInvoices',
                    label: Text('Customer Invoices'),
                    leadingIcon: Icon(Icons.request_quote_outlined),
                    value: 'custInvoices',
                  ),
                  SuperNavNode(
                    id: 'collections',
                    label: Text('Collections'),
                    leadingIcon: Icon(Icons.event_repeat_outlined),
                    value: 'collections',
                    badge: SuperNavBadge('8', tone: SuperNavBadgeTone.warning),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      SuperNavSection(
        title: 'Risk & Compliance',
        items: [
          SuperNavNode(
            id: 'complianceHub',
            label: Text('Compliance'),
            leadingIcon: Icon(Icons.verified_user_outlined),
            children: [
              SuperNavNode(
                id: 'amlGroup',
                label: Text('AML / KYC'),
                children: [
                  SuperNavNode(
                    id: 'sanctions',
                    label: Text('Sanctions Screening'),
                    leadingIcon: Icon(Icons.gpp_maybe_outlined),
                    value: 'sanctions',
                    locked: true,
                    lockMessage: 'Restricted — Compliance Officer only',
                  ),
                  SuperNavNode(
                    id: 'sar',
                    label: Text('Suspicious Activity (SAR)'),
                    leadingIcon: Icon(Icons.flag_outlined),
                    value: 'sar',
                    locked: true,
                    lockMessage: 'Restricted — Compliance Officer only',
                  ),
                ],
              ),
              SuperNavNode(
                id: 'auditGroup',
                label: Text('Audit'),
                children: [
                  SuperNavNode(
                    id: 'auditLog',
                    label: Text('Audit Trail'),
                    leadingIcon: Icon(Icons.history_toggle_off),
                    value: 'auditLog',
                    status: SuperNavNodeStatus.locked,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      SuperNavSection(
        title: 'Reports',
        items: [
          SuperNavNode(
            id: 'reportsHub',
            label: Text('Financial Reports'),
            leadingIcon: Icon(Icons.insert_chart_outlined),
            children: [
              SuperNavNode(
                id: 'finGroup',
                label: Text('Statements'),
                children: [
                  SuperNavNode(
                    id: 'trialBalance',
                    label: Text('Trial Balance'),
                    leadingIcon: Icon(Icons.balance),
                    value: 'trialBalance',
                  ),
                  SuperNavNode(
                    id: 'incomeStmt',
                    label: Text('Income Statement'),
                    leadingIcon: Icon(Icons.trending_up),
                    value: 'incomeStmt',
                  ),
                  SuperNavNode(
                    id: 'balanceSheet',
                    label: Text('Balance Sheet'),
                    leadingIcon: Icon(Icons.table_chart_outlined),
                    value: 'balanceSheet',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];

class ErpBankingExample extends StatefulWidget {
  const ErpBankingExample({super.key});
  @override
  State<ErpBankingExample> createState() => _ErpBankingExampleState();
}

class _ErpBankingExampleState extends State<ErpBankingExample> {
  int _approvals = 7;
  String _screen = 'dashboard';

  late final SuperNavigationSidebarController<String> _nav =
      SuperNavigationSidebarController<String>(
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
    final s = SuperNavigationSidebarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: Column(
        children: [
          // mock app bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(bottom: BorderSide(color: s.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: s.fg1),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  '04 · Banking / accounting ERP',
                  style: TextStyle(
                    fontFamily: SuperNavigationSidebarThemeData.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.fg1,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _approvals += 1);
                    _nav.replaceSections(
                      _bankingSections(approvals: _approvals),
                    );
                  },
                  icon: const Icon(Icons.add_alert_outlined, size: 16),
                  label: Text('New approval ($_approvals)'),
                  style: TextButton.styleFrom(foregroundColor: s.fg2),
                ),
              ],
            ),
          ),
          // body: sidebar + page
          Expanded(
            child: Row(
              children: [
                SuperNavigationSidebar<String>(
                  controller: _nav,
                  mode: SuperNavSidebarMode.expanded,
                  showGuides: true,
                  // ── the ERP capabilities, switched on ──
                  searchable: true,
                  searchHint: 'Search accounts, journals, reports…',
                  favoritable: true,
                  quickAccessTitle: 'Quick Access',
                  header: (ctx, collapsed) => _Brand(collapsed: collapsed),
                  onNavigate: (n) => setState(() => _screen = n.value!),
                ),
                Expanded(
                  child: _Page(nav: _nav, screen: _screen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand header ──────────────────────────────────────────────────
class _Brand extends StatelessWidget {
  final bool collapsed;
  const _Brand({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = SuperNavigationSidebarThemeData.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SuperNavigationSidebarThemeData.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance,
              size: 15,
              color: Colors.white,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Text(
              'Meridian Bank',
              style: TextStyle(
                fontFamily: SuperNavigationSidebarThemeData.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: s.fg1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Active page — breadcrumb + capability legend ──────────────────
class _Page extends StatelessWidget {
  final SuperNavigationSidebarController<String> nav;
  final String screen;
  const _Page({required this.nav, required this.screen});

  @override
  Widget build(BuildContext context) {
    final s = SuperNavigationSidebarThemeData.of(context);
    final node = nav.node(screen);
    final crumb = [
      ...SuperNavOps.ancestorsOf<String>(
        nav.sections,
        screen,
      ).map((id) => _plainExampleLabel(nav.node(id), fallback: id)),
      if (node != null) _plainExampleLabel(node, fallback: screen),
    ].join('  ›  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            crumb.toUpperCase(),
            style: TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.monoFont,
              fontSize: 10.5,
              letterSpacing: 1.4,
              color: s.fg4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _plainExampleLabel(node, fallback: 'Workspace'),
            style: TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: s.fg1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border.all(color: s.border),
              borderRadius: BorderRadius.circular(s.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try the ERP capabilities',
                  style: TextStyle(
                    fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: s.fg1,
                  ),
                ),
                const SizedBox(height: 14),
                _legend(
                  s,
                  Icons.search,
                  'Search',
                  'Type in the field above the tree — it filters every level, auto-expands matches and highlights the hit.',
                ),
                _legend(
                  s,
                  Icons.star_rounded,
                  'Quick Access',
                  'Hover any destination and tap the star. Starred screens surface in the band at the top. Journal Entry, Trial Balance & Approvals are pre-pinned.',
                ),
                _legend(
                  s,
                  Icons.lock_outline,
                  'Locked screens',
                  'Wire / SWIFT, Payment Run and the Compliance screens are permission-gated — dimmed, not clickable, with a reason tooltip on hover.',
                ),
                _legend(
                  s,
                  Icons.circle,
                  'Status dots',
                  'Fiscal periods carry state: Q3 open (green), Q2 closed (grey), Q1 locked (red), Reconciliation needs attention (amber).',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(
    SuperNavigationSidebarThemeData s,
    IconData icon,
    String title,
    String body,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SuperNavigationSidebarThemeData.accent
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: SuperNavigationSidebarThemeData.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: s.fg1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                    fontSize: 12.5,
                    height: 1.5,
                    color: s.fg3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _plainExampleLabel<T>(SuperNavNode<T>? node,
    {required String fallback}) {
  if (node == null) return fallback;
  final label = node.label;
  if (label is Text)
    return label.data ?? label.textSpan?.toPlainText() ?? node.id;
  return node.keywords.isNotEmpty ? node.keywords.first : node.id;
}
