// ============================================================
// Example 07 · Kitchen sink — every feature on one screen
// ------------------------------------------------------------
// One comprehensive workbench that exercises the FULL 2.2 surface:
//
//   Shell        NavigationShell (spanning/inset · push/overlay · adaptive
//                or forced mode) + NavigationSidebarAppBar (back button,
//                breadcrumb, global search, middle slot, actions).
//   Tree         codes (SAP-style) · hidden keywords · badges (all tones) ·
//                shortcut chords · locked · disabled · status dots ·
//                footer section · deep module→group→item nesting.
//   Search       inline filter (searchable) OR command palette
//                (allowSearchDialog) with ↑↓/↵/esc + "Recent" band.
//   2.2          NavShortcutBinder (Ctrl+Shift+D, +A, +J, +H) · recents ·
//                snapshot save/restore · aggregateBadges roll-up.
//   Chrome       favorites/Quick Access · guides · rail flyouts · pane
//                toggle · shortcut-hint mode · Fluent bar indicator ·
//                RTL + Arabic localizations · live replaceSections.
//
// The content area is a control panel: every switch drives the real
// widget, and a live state readout shows active/recents/favorites/history
// plus the saved snapshot JSON.
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

class KitchenSinkExample extends StatefulWidget {
  const KitchenSinkExample({super.key});
  @override
  State<KitchenSinkExample> createState() => _KitchenSinkExampleState();
}

class _KitchenSinkExampleState extends State<KitchenSinkExample> {
  late final NavigationSidebarController<String> _nav;

  // ── back-history simulation (drives canGoBack) ─────────────
  final List<String> _history = [];
  String? _prevActive = 'dashboard';

  // ── live toggles ───────────────────────────────────────────
  bool _rtl = false;
  NavSelectionIndicator _indicator = NavSelectionIndicator.fill;
  NavShellHeaderLayout _headerLayout = NavShellHeaderLayout.spanning;
  NavPaneBehavior _paneBehavior = NavPaneBehavior.push;
  NavSidebarMode? _forcedMode; // null = adaptive from width
  int _searchMode = 2; // 0 = none · 1 = inline filter · 2 = command palette
  bool _favoritable = true;
  bool _aggregateBadges = true;
  bool _showGuides = true;
  bool _railFlyouts = true;
  bool _showPaneToggle = false;
  NavShortcutMode _shortcutMode = NavShortcutMode.onHover;

  // ── live data ──────────────────────────────────────────────
  int _approvals = 3;
  String? _snapshotJson;

  NavigationSidebarLocalizations get _l10n => _rtl
      ? NavigationSidebarLocalizations.arabic
      : const NavigationSidebarLocalizations();

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _buildSections(_approvals),
      active: 'dashboard',
      favorites: {'journalEntry', 'trialBalance'},
      maxRecents: 8,
    );
    _nav.addListener(_onNav);
  }

  @override
  void dispose() {
    _nav.removeListener(_onNav);
    _nav.dispose();
    super.dispose();
  }

  void _onNav() {
    if (mounted) setState(() {});
  }

  // ── the tree: every NavNode feature in one forest ──────────
  List<NavSection<String>> _buildSections(int approvals) => [
        NavSection(title: 'Overview', items: [
          NavNode(
            id: 'dashboard',
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            value: 'dashboard',
            code: 'DB01',
            shortcut: ['ctrl', 'shift', 'd'],
          ),
          NavNode(
            id: 'approvals',
            label: 'Approvals',
            icon: Icons.fact_check_outlined,
            value: 'approvals',
            code: 'AP01',
            shortcut: ['ctrl', 'shift', 'a'],
            badge: NavBadge('$approvals', tone: NavBadgeTone.danger),
          ),
          NavNode(
            id: 'inbox',
            label: 'Inbox',
            icon: Icons.inbox_outlined,
            value: 'inbox',
            badge: NavBadge('12'),
          ),
        ]),
        NavSection(title: 'Finance', items: [
          NavNode(
            id: 'financeHub',
            label: 'Finance',
            icon: Icons.account_balance_outlined,
            children: [
              NavNode(id: 'ledger', label: 'Ledger', children: [
                NavNode(
                  id: 'journalEntry',
                  label: 'Journal Entry',
                  icon: Icons.edit_note_outlined,
                  value: 'journalEntry',
                  code: 'JE01',
                  keywords: ['قيد يومية', 'voucher', 'GL entry'],
                  shortcut: ['ctrl', 'shift', 'j'],
                  badge: NavBadge('9', tone: NavBadgeTone.warning),
                ),
                NavNode(
                  id: 'trialBalance',
                  label: 'Trial Balance',
                  icon: Icons.balance,
                  value: 'trialBalance',
                  code: 'TB01',
                  keywords: ['ميزان مراجعة'],
                  status: NavNodeStatus.open,
                ),
                NavNode(
                  id: 'wire',
                  label: 'Wire / SWIFT',
                  icon: Icons.bolt_outlined,
                  value: 'wire',
                  locked: true,
                  lockMessage: 'Requires Treasury Approver role',
                ),
                NavNode(
                  id: 'closing',
                  label: 'Period Closing',
                  icon: Icons.event_repeat_outlined,
                  value: 'closing',
                  status: NavNodeStatus.attention,
                ),
              ]),
              NavNode(id: 'periods', label: 'Fiscal Periods', children: [
                NavNode(
                  id: 'fy25q3',
                  label: 'FY2025 · Q3',
                  icon: Icons.event_available_outlined,
                  value: 'fy25q3',
                  status: NavNodeStatus.open,
                ),
                NavNode(
                  id: 'fy25q2',
                  label: 'FY2025 · Q2',
                  icon: Icons.event_outlined,
                  value: 'fy25q2',
                  status: NavNodeStatus.closed,
                ),
                NavNode(
                  id: 'fy25q1',
                  label: 'FY2025 · Q1',
                  icon: Icons.lock_clock_outlined,
                  value: 'fy25q1',
                  status: NavNodeStatus.locked,
                ),
              ]),
            ],
          ),
          NavNode(
            id: 'salesHub',
            label: 'Sales',
            icon: Icons.storefront_outlined,
            children: [
              NavNode(id: 'salesDocs', label: 'Documents', children: [
                NavNode(
                  id: 'quotes',
                  label: 'Quotations',
                  icon: Icons.request_quote_outlined,
                  value: 'quotes',
                  badge: NavBadge('3'),
                ),
                NavNode(
                  id: 'orders',
                  label: 'Sales Orders',
                  icon: Icons.shopping_cart_checkout_outlined,
                  value: 'orders',
                  code: 'SO01',
                ),
                NavNode(
                  id: 'invoices',
                  label: 'Customer Invoices',
                  icon: Icons.receipt_long_outlined,
                  value: 'invoices',
                  code: 'AR-INV',
                  keywords: ['فاتورة عميل', 'bill', 'receivable'],
                  badge: NavBadge('Live', tone: NavBadgeTone.success),
                ),
              ]),
            ],
          ),
          NavNode(
            id: 'inventoryHub',
            label: 'Inventory',
            icon: Icons.inventory_2_outlined,
            children: [
              NavNode(id: 'invGroup', label: 'Stock', children: [
                NavNode(
                  id: 'items',
                  label: 'Items',
                  icon: Icons.category_outlined,
                  value: 'items',
                ),
                NavNode(
                  id: 'warehouses',
                  label: 'Warehouses',
                  icon: Icons.warehouse_outlined,
                  value: 'warehouses',
                  enabled: false, // disabled row — visible, not activatable
                ),
              ]),
            ],
          ),
        ]),
        NavSection(
          title: '',
          placement: NavSectionPlacement.footer,
          items: [
            NavNode(
              id: 'help',
              label: 'Help & Docs',
              icon: Icons.help_outline,
              value: 'help',
              shortcut: ['ctrl', 'shift', 'h'],
            ),
            NavNode(
              id: 'settings',
              label: 'Settings',
              icon: Icons.settings_outlined,
              value: 'settings',
              code: 'SET01',
            ),
          ],
        ),
      ];

  // ── navigation + back history ──────────────────────────────
  void _handleNavigate(NavNode<String> n) {
    setState(() {
      if (_prevActive != null && _prevActive != n.id) {
        _history.add(_prevActive!);
      }
      _prevActive = n.id;
      _nav.canGoBack = _history.isNotEmpty;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    final id = _history.removeLast();
    if (_nav.navigate(id)) {
      _prevActive = id;
    }
    setState(() => _nav.canGoBack = _history.isNotEmpty);
  }

  // ── 2.2 actions ────────────────────────────────────────────
  void _saveSnapshot() => setState(
      () => _snapshotJson = jsonEncode(_nav.snapshot().toJson()));

  void _restoreSnapshot() {
    final raw = _snapshotJson;
    if (raw == null) return;
    _nav.restore(NavSidebarStateSnapshot.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map)));
  }

  void _bumpApprovals() {
    _approvals++;
    _nav.replaceSections(_buildSections(_approvals)); // live hot-swap
  }

  // ════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final base = NavigationSidebarThemeData.of(context);
    final themed = Theme.of(context).copyWith(extensions: [
      base.copyWith(selectionIndicator: _indicator),
    ]);

    return Theme(
      data: themed,
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          // 2.2 — shortcuts (Ctrl+Shift+D / A / J / H) navigate for real:
        child: NavShortcutBinder<String>(
          controller: _nav,
          onNavigate: _handleNavigate,
          child: NavigationShell<String>(
            controller: _nav,
            mode: _forcedMode, // null = adaptive from width
            headerLayout: _headerLayout,
            paneBehavior: _paneBehavior,
            appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
              controller: _nav,
              mode: mode,
              showBackButton: true,
              onBack: _goBack,
              title: const Text('GeniusLink ERP'),
              pageTitle: NavBreadcrumb<String>(controller: _nav),
              globalSearch: _searchMode == 1
                  ? NavigationSidebarSearchField(
                      controller: _nav,
                      hint: 'Filter navigation…',
                    )
                  : null,
              middle: const _EnvBadge(),
              actions: [
                _BarIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: _bumpApprovals,
                  tooltip: '+1 approval badge (replaceSections)',
                ),
                const _Avatar(),
              ],
              localizations: _l10n,
            ),
            sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
              controller: _nav,
              mode: mode,
              header: (ctx, collapsed) => _Brand(collapsed: collapsed),
              searchable: _searchMode == 1,
              allowSearchDialog: _searchMode == 2,
              searchHint:
                  _rtl ? 'ابحث بالاسم أو الرمز…' : 'Search name or code…',
              favoritable: _favoritable,
              aggregateBadges: _aggregateBadges,
              showGuides: _showGuides,
              railFlyouts: _railFlyouts,
              showPaneToggle: _showPaneToggle,
              shortcutMode: _shortcutMode,
              localizations: _l10n,
              onNavigate: _handleNavigate,
            ),
            body: _controlPanel(context),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // CONTENT — control panel + live state readout
  // ════════════════════════════════════════════════════════
  Widget _controlPanel(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final active = _nav.active == null ? null : _nav.node(_nav.active!);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── active screen header ─────────────────────────────
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(active?.label ?? '—',
                        style: TextStyle(
                            fontFamily:
                                NavigationSidebarThemeData.displayFont,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: t.fg1)),
                    if (active?.code != null) ...[
                      const SizedBox(width: 10),
                      _CodeChip(active!.code!),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Every package feature is live on this screen — flip the '
                      'switches, press Ctrl+Shift+D / A / J / H, open the palette.',
                      style: TextStyle(fontSize: 13, color: t.fg3)),
                ]),
          ),
        ]),
        const SizedBox(height: 20),

        // ── toggle groups ────────────────────────────────────
        Wrap(spacing: 12, runSpacing: 12, children: [
          _Group(title: 'Mode', children: [
            _Seg(
                label: 'Auto',
                on: _forcedMode == null,
                onTap: () => setState(() => _forcedMode = null)),
            _Seg(
                label: 'Expanded',
                on: _forcedMode == NavSidebarMode.expanded,
                onTap: () =>
                    setState(() => _forcedMode = NavSidebarMode.expanded)),
            _Seg(
                label: 'Rail',
                on: _forcedMode == NavSidebarMode.rail,
                onTap: () =>
                    setState(() => _forcedMode = NavSidebarMode.rail)),
            _Seg(
                label: 'Drawer',
                on: _forcedMode == NavSidebarMode.drawer,
                onTap: () =>
                    setState(() => _forcedMode = NavSidebarMode.drawer)),
          ]),
          _Group(title: 'Header', children: [
            _Seg(
                label: 'Spanning',
                on: _headerLayout == NavShellHeaderLayout.spanning,
                onTap: () => setState(
                    () => _headerLayout = NavShellHeaderLayout.spanning)),
            _Seg(
                label: 'Inset',
                on: _headerLayout == NavShellHeaderLayout.inset,
                onTap: () => setState(
                    () => _headerLayout = NavShellHeaderLayout.inset)),
          ]),
          _Group(title: 'Pane', children: [
            _Seg(
                label: 'Push',
                on: _paneBehavior == NavPaneBehavior.push,
                onTap: () =>
                    setState(() => _paneBehavior = NavPaneBehavior.push)),
            _Seg(
                label: 'Overlay',
                on: _paneBehavior == NavPaneBehavior.overlay,
                onTap: () => setState(() {
                      _paneBehavior = NavPaneBehavior.overlay;
                      _nav.collapsed = true; // overlay starts closed
                    })),
          ]),
          _Group(title: 'Search', children: [
            _Seg(
                label: 'None',
                on: _searchMode == 0,
                onTap: () => setState(() => _searchMode = 0)),
            _Seg(
                label: 'Inline filter',
                on: _searchMode == 1,
                onTap: () => setState(() => _searchMode = 1)),
            _Seg(
                label: 'Palette',
                on: _searchMode == 2,
                onTap: () => setState(() => _searchMode = 2)),
          ]),
          _Group(title: 'Indicator', children: [
            _Seg(
                label: 'Fill',
                on: _indicator == NavSelectionIndicator.fill,
                onTap: () => setState(
                    () => _indicator = NavSelectionIndicator.fill)),
            _Seg(
                label: 'Bar',
                on: _indicator == NavSelectionIndicator.bar,
                onTap: () =>
                    setState(() => _indicator = NavSelectionIndicator.bar)),
          ]),
          _Group(title: 'Shortcut hints', children: [
            _Seg(
                label: 'Hover',
                on: _shortcutMode == NavShortcutMode.onHover,
                onTap: () => setState(
                    () => _shortcutMode = NavShortcutMode.onHover)),
            _Seg(
                label: 'Always',
                on: _shortcutMode == NavShortcutMode.always,
                onTap: () =>
                    setState(() => _shortcutMode = NavShortcutMode.always)),
            _Seg(
                label: 'Hidden',
                on: _shortcutMode == NavShortcutMode.hidden,
                onTap: () =>
                    setState(() => _shortcutMode = NavShortcutMode.hidden)),
          ]),
          _Group(title: 'Chrome', children: [
            _Seg(
                label: 'Favorites',
                on: _favoritable,
                onTap: () => setState(() => _favoritable = !_favoritable)),
            _Seg(
                label: 'Badge roll-up',
                on: _aggregateBadges,
                onTap: () =>
                    setState(() => _aggregateBadges = !_aggregateBadges)),
            _Seg(
                label: 'Guides',
                on: _showGuides,
                onTap: () => setState(() => _showGuides = !_showGuides)),
            _Seg(
                label: 'Flyouts',
                on: _railFlyouts,
                onTap: () => setState(() => _railFlyouts = !_railFlyouts)),
            _Seg(
                label: 'Pane toggle',
                on: _showPaneToggle,
                onTap: () =>
                    setState(() => _showPaneToggle = !_showPaneToggle)),
            _Seg(
                label: 'RTL / عربي',
                on: _rtl,
                onTap: () => setState(() => _rtl = !_rtl)),
          ]),
        ]),
        const SizedBox(height: 16),

        // ── action buttons ───────────────────────────────────
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Btn(
              icon: Icons.save_outlined,
              label: 'Save snapshot',
              onTap: _saveSnapshot),
          _Btn(
              icon: Icons.restore,
              label: 'Restore snapshot',
              enabled: _snapshotJson != null,
              onTap: _restoreSnapshot),
          _Btn(
              icon: Icons.history_toggle_off,
              label: 'Clear recents',
              onTap: _nav.clearRecents),
          _Btn(
              icon: Icons.add_alert_outlined,
              label: '+1 approval badge',
              onTap: _bumpApprovals),
          _Btn(
              icon: Icons.keyboard_command_key,
              label: 'Open palette',
              onTap: () => showNavSearchDialog<String>(
                    context,
                    controller: _nav,
                    hint: _rtl
                        ? 'ابحث بالاسم أو الرمز…'
                        : 'Search name or code…',
                    recentsLabel: _l10n.recentsTitle,
                    onPick: (id) {
                      // With onPick provided the dialog delegates navigation:
                      if (!_nav.navigate(id)) return;
                      final n = _nav.node(id);
                      if (n != null) _handleNavigate(n);
                    },
                  )),
        ]),
        const SizedBox(height: 20),

        // ── live state readout ───────────────────────────────
        _StateCard(title: 'Live controller state', rows: [
          ('active', _nav.active ?? '—'),
          ('activeValue', '${_nav.activeValue}'),
          ('canGoBack', '${_nav.canGoBack}  (history: ${_history.length})'),
          ('collapsed', '${_nav.collapsed}'),
          ('recents (MRU)', _nav.recents.isEmpty ? '—' : _nav.recents.join(' · ')),
          ('favorites', _nav.favorites.isEmpty ? '—' : _nav.favorites.join(' · ')),
          ('approvals badge', '$_approvals  (via replaceSections)'),
          (
            'snapshot',
            _snapshotJson == null
                ? '— press "Save snapshot"'
                : (_snapshotJson!.length > 120
                    ? '${_snapshotJson!.substring(0, 120)}…'
                    : _snapshotJson!)
          ),
        ]),
        const SizedBox(height: 12),
        _StateCard(title: 'Try the 2.2 features', rows: const [
          ('shortcuts', 'press  Ctrl+Shift+D · +A · +J · +H  (not while typing)'),
          ('codes', 'palette-search "JE01", "AR-INV" or "SET01"'),
          ('keywords', 'palette-search "voucher", "قيد" or "bill"'),
          ('recents', 'navigate a few screens, then open the palette empty'),
          ('roll-up', 'collapse Finance — the closed row shows the summed count'),
          ('locked', 'Wire / SWIFT refuses navigation + shows the reason'),
          ('snapshot', 'star + expand things → Save → change → Restore'),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ════════════════════════════════════════════════════════════
class _Brand extends StatelessWidget {
  final bool collapsed;
  const _Brand({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mark = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('GL',
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.displayFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
    if (collapsed) return Center(child: mark);
    return Row(children: [
      mark,
      const SizedBox(width: 10),
      Expanded(
        child: Text('GeniusLink',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.displayFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: t.fg1)),
      ),
    ]);
  }
}

class _EnvBadge extends StatelessWidget {
  const _EnvBadge();
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: NavigationSidebarThemeData.success.withValues(alpha: 0.35)),
      ),
      child: Text('PRODUCTION',
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: t.fg2)),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
            color: NavigationSidebarThemeData.accent.withValues(alpha: 0.4)),
      ),
      child: const Text('AR',
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: NavigationSidebarThemeData.accent)),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _BarIcon(
      {required this.icon, required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 19, color: t.fg2),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String code;
  const _CodeChip(this.code);
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: t.border),
      ),
      child: Text(code,
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: t.fg3)),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: t.fg4)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: children),
      ]),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    const accent = NavigationSidebarThemeData.accent;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: NavigationSidebarThemeData.durFast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? accent : t.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? accent : t.fg2)),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _Btn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(color: t.borderStrong),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: NavigationSidebarThemeData.accent),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.bodyFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.fg1)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _StateCard({required this.title, required this.rows});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusXl),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: t.fg4)),
        const SizedBox(height: 10),
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(k,
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.monoFont,
                            fontSize: 11,
                            color: t.fg3)),
                  ),
                  Expanded(
                    child: Text(v,
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.monoFont,
                            fontSize: 11,
                            color: t.fg1)),
                  ),
                ]),
          ),
      ]),
    );
  }
}
