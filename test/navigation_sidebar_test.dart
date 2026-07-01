// super_navigation_sidebar — comprehensive test suite
//
// Coverage:
//   • NavigationSidebarLocalizations — strings, helpers, presets
//   • NavNode / NavSection deep immutability
//   • NavOps.findDuplicateIds — duplicate detection
//   • NavigationSidebarController — duplicate ID assertion, navigation
//     safety, navigate() return value, expansion, favorites, search,
//     drawer, replaceSections, ownsActive
//   • NavigationSidebar widget — onNavigate gating, locked/disabled
//     in rail mode, drawer mode, RTL, search empty state, favorites band
//   • NavigationSidebarAppBar — renders in drawer mode (hamburger),
//     renders in expanded mode (collapse toggle), NavBreadcrumb

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

// ── helpers ────────────────────────────────────────────────────────

/// Minimal section list used across multiple tests.
List<NavSection<String>> _basicSections({int approvals = 3}) => [
      NavSection<String>(title: 'Overview', items: [
        NavNode(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          value: 'dashboard',
        ),
        NavNode(
          id: 'approvals',
          label: 'Approvals',
          icon: Icons.fact_check_outlined,
          value: 'approvals',
          badge: NavBadge('$approvals', tone: NavBadgeTone.danger),
        ),
      ]),
      NavSection<String>(title: 'Finance', items: [
        NavNode(
          id: 'financeHub',
          label: 'Finance',
          icon: Icons.account_balance_outlined,
          children: [
            NavNode(id: 'ledgerGroup', label: 'Ledger', children: [
              NavNode(
                id: 'journalEntry',
                label: 'Journal Entry',
                icon: Icons.edit_note_outlined,
                value: 'journalEntry',
                shortcut: ['g', 'j'],
              ),
              NavNode(
                id: 'wire',
                label: 'Wire / SWIFT',
                icon: Icons.bolt_outlined,
                value: 'wire',
                locked: true,
                lockMessage: 'Requires Treasury Approver role',
              ),
            ]),
          ],
        ),
      ]),
      NavSection<String>(title: 'Settings', items: [
        NavNode(
          id: 'settings',
          label: 'Settings',
          icon: Icons.settings_outlined,
          value: 'settings',
          enabled: false,
        ),
      ]),
    ];

/// Wraps a widget in the minimal boilerplate needed to render the sidebar.
Widget _wrap(Widget child, {bool dark = true, bool rtl = false}) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        dark
            ? NavigationSidebarThemeData.dark
            : NavigationSidebarThemeData.light
      ],
    ),
    home: Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(body: child),
    ),
  );
}

// ════════════════════════════════════════════════════════════
// 1. NavigationSidebarLocalizations
// ════════════════════════════════════════════════════════════
void main() {
  group('NavigationSidebarLocalizations', () {
    test('default English strings are non-empty', () {
      const l10n = NavigationSidebarLocalizations();
      expect(l10n.searchHint, isNotEmpty);
      expect(l10n.searchEmpty, contains('{query}'));
      expect(l10n.drawerTitle, isNotEmpty);
      expect(l10n.drawerCloseLabel, isNotEmpty);
      expect(l10n.quickAccessTitle, isNotEmpty);
      expect(l10n.addToQuickAccess, isNotEmpty);
      expect(l10n.removeFromQuickAccess, isNotEmpty);
      expect(l10n.lockedDefault, isNotEmpty);
      expect(l10n.shortcutPrefix, isNotEmpty);
      expect(l10n.shortcutSeparator, isNotEmpty);
    });

    test('searchEmptyFor substitutes {query}', () {
      const l10n = NavigationSidebarLocalizations();
      final result = l10n.searchEmptyFor('journals');
      expect(result, contains('journals'));
      expect(result, isNot(contains('{query}')));
    });

    test('searchEmptyFor with custom template', () {
      const l10n = NavigationSidebarLocalizations(
        searchEmpty: 'Aucun résultat pour «\u202f{query}\u202f»',
      );
      expect(l10n.searchEmptyFor('test'), contains('test'));
      expect(l10n.searchEmptyFor('test'), isNot(contains('{query}')));
    });

    test('shortcutTooltip builds correct string', () {
      const l10n = NavigationSidebarLocalizations(
        shortcutPrefix: 'Shortcut · ',
        shortcutSeparator: ' then ',
      );
      expect(l10n.shortcutTooltip(['g', 'd']), 'Shortcut · G then D');
      expect(l10n.shortcutTooltip([]), isEmpty);
      expect(l10n.shortcutTooltip(['x']), 'Shortcut · X');
    });

    test('Arabic preset has non-empty strings', () {
      const l10n = NavigationSidebarLocalizations.arabic;
      expect(l10n.searchHint, isNotEmpty);
      expect(l10n.drawerTitle, isNotEmpty);
      expect(l10n.lockedDefault, isNotEmpty);
      expect(l10n.searchEmptyFor('test'), contains('test'));
    });

    test('custom override inherits remaining defaults', () {
      const l10n = NavigationSidebarLocalizations(
        searchHint: 'Buscar…',
      );
      expect(l10n.searchHint, 'Buscar…');
      // All other fields keep English defaults:
      expect(l10n.drawerTitle, 'Navigation');
      expect(l10n.addToQuickAccess, 'Add to Quick Access');
    });

    test('equality and hashCode', () {
      const a = NavigationSidebarLocalizations();
      const b = NavigationSidebarLocalizations();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      const c = NavigationSidebarLocalizations(searchHint: 'Custom');
      expect(a, isNot(equals(c)));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. NavNode / NavSection — deep immutability
  // ════════════════════════════════════════════════════════════
  group('NavNode deep immutability', () {
    test('children list cannot be mutated externally', () {
      final mutableList = [
        NavNode(id: 'child', label: 'Child'),
      ];
      final node =
          NavNode(id: 'parent', label: 'Parent', children: mutableList);
      expect(node.children.length, 1);

      // Mutating the original list must NOT affect the node.
      mutableList.add(NavNode(id: 'intruder', label: 'Intruder'));
      expect(node.children.length, 1,
          reason: 'children list should be unmodifiable');

      // Direct mutation of node.children must throw.
      expect(
        () => (node.children as List).add(NavNode(id: 'x', label: 'X')),
        throwsUnsupportedError,
      );
    });

    test('default empty children is already unmodifiable', () {
      final node = NavNode(id: 'leaf', label: 'Leaf');
      expect(node.children, isEmpty);
      expect(
        () => (node.children as List).add(NavNode(id: 'x', label: 'X')),
        throwsUnsupportedError,
      );
    });

    test('copyWith re-wraps children as unmodifiable', () {
      final original =
          NavNode(id: 'p', label: 'Parent', children: [
        NavNode(id: 'c1', label: 'C1'),
      ]);
      final copy = original.copyWith(
        children: [NavNode(id: 'c2', label: 'C2')],
      );
      expect(copy.children.length, 1);
      expect(copy.children.first.id, 'c2');
      expect(
        () => (copy.children as List).add(NavNode(id: 'x', label: 'X')),
        throwsUnsupportedError,
      );
    });
  });

  group('NavSection deep immutability', () {
    test('items list cannot be mutated externally', () {
      final mutableItems = [NavNode<String>(id: 'a', label: 'A')];
      final section = NavSection<String>(title: 'Test', items: mutableItems);
      expect(section.items.length, 1);

      mutableItems.add(NavNode(id: 'b', label: 'B'));
      expect(section.items.length, 1,
          reason: 'items should be unmodifiable');

      expect(
        () => (section.items as List).add(NavNode(id: 'x', label: 'X')),
        throwsUnsupportedError,
      );
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. NavOps.findDuplicateIds
  // ════════════════════════════════════════════════════════════
  group('NavOps.findDuplicateIds', () {
    test('returns empty list for a valid tree', () {
      expect(
        NavOps.findDuplicateIds<String>(_basicSections()),
        isEmpty,
      );
    });

    test('detects duplicates at same depth', () {
      final sections = [
        NavSection<String>(title: 'S', items: [
          NavNode(id: 'dup', label: 'A'),
          NavNode(id: 'dup', label: 'B'),
        ]),
      ];
      expect(NavOps.findDuplicateIds<String>(sections), contains('dup'));
    });

    test('detects duplicate across sections', () {
      final sections = [
        NavSection<String>(title: 'S1', items: [NavNode(id: 'x', label: 'X1')]),
        NavSection<String>(title: 'S2', items: [NavNode(id: 'x', label: 'X2')]),
      ];
      expect(NavOps.findDuplicateIds<String>(sections), contains('x'));
    });

    test('detects duplicate across different depths', () {
      final sections = [
        NavSection<String>(title: 'S', items: [
          NavNode(id: 'shared', label: 'Parent', children: [
            NavNode(id: 'child', label: 'Child', children: [
              NavNode(id: 'shared', label: 'Deep duplicate'),
            ]),
          ]),
        ]),
      ];
      expect(NavOps.findDuplicateIds<String>(sections), contains('shared'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 4. NavigationSidebarController — navigation safety
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController.navigate() safety', () {
    late NavigationSidebarController<String> nav;

    setUp(() {
      nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
      );
    });

    tearDown(() => nav.dispose());

    test('navigate() returns true for a valid leaf', () {
      expect(nav.navigate('journalEntry'), isTrue);
      expect(nav.active, 'journalEntry');
    });

    test('navigate() returns false and does not change active for locked node', () {
      final before = nav.active;
      final result = nav.navigate('wire');
      expect(result, isFalse);
      expect(nav.active, before,
          reason: 'active must not change when navigation is refused');
    });

    test('navigate() returns false for disabled node', () {
      final before = nav.active;
      final result = nav.navigate('settings');
      expect(result, isFalse);
      expect(nav.active, before);
    });

    test('navigate() returns false for unknown id', () {
      expect(nav.navigate('nonexistent'), isFalse);
    });

    test('navigate() auto-expands ancestors', () {
      nav.navigate('journalEntry');
      expect(nav.isExpanded('financeHub'), isTrue);
      expect(nav.isExpanded('ledgerGroup'), isTrue);
    });

    test('navigate() closes the drawer on success', () {
      nav.openDrawer();
      expect(nav.drawerOpen, isTrue);
      nav.navigate('dashboard');
      expect(nav.drawerOpen, isFalse);
    });

    test('navigate() does NOT close the drawer when refused', () {
      nav.openDrawer();
      nav.navigate('wire'); // locked — should be refused
      expect(nav.drawerOpen, isTrue,
          reason: 'drawer must stay open when navigation is refused');
    });

    test('notifyListeners not called when nothing changes', () {
      nav.navigate('dashboard'); // already active
      int calls = 0;
      nav.addListener(() => calls++);
      nav.navigate('dashboard');
      expect(calls, 0);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 5. NavigationSidebarController — expansion
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController expansion', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
        ));
    tearDown(() => nav.dispose());

    test('expand / collapse / toggleNode', () {
      expect(nav.isExpanded('financeHub'), isFalse);
      nav.expand('financeHub');
      expect(nav.isExpanded('financeHub'), isTrue);
      nav.collapse('financeHub');
      expect(nav.isExpanded('financeHub'), isFalse);
      nav.toggleNode('financeHub');
      expect(nav.isExpanded('financeHub'), isTrue);
    });

    test('expandAll / collapseAll', () {
      nav.expandAll();
      expect(nav.isExpanded('financeHub'), isTrue);
      expect(nav.isExpanded('ledgerGroup'), isTrue);
      nav.collapseAll();
      expect(nav.isExpanded('financeHub'), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 6. NavigationSidebarController — favorites
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController favorites', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
          favorites: {'dashboard'},
        ));
    tearDown(() => nav.dispose());

    test('seeded favorites are present', () {
      expect(nav.isFavorite('dashboard'), isTrue);
      expect(nav.favorites, contains('dashboard'));
    });

    test('toggleFavorite adds and removes', () {
      expect(nav.isFavorite('approvals'), isFalse);
      nav.toggleFavorite('approvals');
      expect(nav.isFavorite('approvals'), isTrue);
      nav.toggleFavorite('approvals');
      expect(nav.isFavorite('approvals'), isFalse);
    });

    test('setFavorites replaces the set', () {
      nav.setFavorites(['approvals', 'journalEntry']);
      expect(nav.isFavorite('dashboard'), isFalse);
      expect(nav.isFavorite('approvals'), isTrue);
      expect(nav.isFavorite('journalEntry'), isTrue);
    });

    test('favoriteNodes returns nodes in tree order', () {
      nav.setFavorites(['journalEntry', 'dashboard']);
      final nodes = nav.favoriteNodes;
      // dashboard appears before journalEntry in the tree
      expect(nodes.map((n) => n.id).toList(),
          ['dashboard', 'journalEntry']);
    });

    test('favorites set is unmodifiable', () {
      expect(
        () => (nav.favorites as Set).add('x'),
        throwsUnsupportedError,
      );
    });
  });

  // ════════════════════════════════════════════════════════════
  // 7. NavigationSidebarController — search / matchSet
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController search', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
        ));
    tearDown(() => nav.dispose());

    test('matchSet empty when no query', () {
      expect(nav.matchSet(), isEmpty);
    });

    test('matchSet returns matched leaf + ancestors', () {
      nav.setQuery('Journal');
      final ms = nav.matchSet();
      expect(ms, contains('journalEntry'));
      // ancestors must also be in the set so the tree can show them
      expect(ms, contains('financeHub'));
      expect(ms, contains('ledgerGroup'));
    });

    test('matchSet empty for no-hit query', () {
      nav.setQuery('xyzzy_not_found');
      expect(nav.matchSet(), isEmpty);
    });

    test('matchSet is case-insensitive', () {
      nav.setQuery('DASHBOARD');
      expect(nav.matchSet(), contains('dashboard'));
    });

    test('filtering getter', () {
      expect(nav.filtering, isFalse);
      nav.setQuery('  '); // whitespace only
      expect(nav.filtering, isFalse);
      nav.setQuery('x');
      expect(nav.filtering, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 8. NavigationSidebarController — ownsActive
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController.ownsActive', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
          active: 'journalEntry',
        ));
    tearDown(() => nav.dispose());

    test('ancestor modules own active', () {
      expect(nav.ownsActive('financeHub'), isTrue);
      expect(nav.ownsActive('ledgerGroup'), isTrue);
    });

    test('non-ancestor does not own active', () {
      expect(nav.ownsActive('dashboard'), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 9. NavigationSidebarController — replaceSections
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController.replaceSections', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
          active: 'dashboard',
        ));
    tearDown(() => nav.dispose());

    test('clears active when it no longer exists', () {
      nav.replaceSections([
        NavSection(title: 'New', items: [
          NavNode(id: 'newNode', label: 'New Node'),
        ]),
      ]);
      expect(nav.active, isNull);
    });

    test('preserves active when it still exists', () {
      final updated = _basicSections(approvals: 9);
      nav.replaceSections(updated);
      expect(nav.active, 'dashboard');
    });

    test('notifies listeners on replace', () {
      int calls = 0;
      nav.addListener(() => calls++);
      nav.replaceSections(_basicSections());
      expect(calls, 1);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 10. NavigationSidebarController — drawer
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController drawer', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
        ));
    tearDown(() => nav.dispose());

    test('openDrawer / closeDrawer / toggleDrawer', () {
      expect(nav.drawerOpen, isFalse);
      nav.openDrawer();
      expect(nav.drawerOpen, isTrue);
      nav.closeDrawer();
      expect(nav.drawerOpen, isFalse);
      nav.toggleDrawer();
      expect(nav.drawerOpen, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 11. NavigationSidebarController — rail (collapsed)
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebarController rail', () {
    late NavigationSidebarController<String> nav;
    setUp(() => nav = NavigationSidebarController<String>(
          sections: _basicSections(),
        ));
    tearDown(() => nav.dispose());

    test('collapsed setter and toggleCollapsed', () {
      expect(nav.collapsed, isFalse);
      nav.collapsed = true;
      expect(nav.collapsed, isTrue);
      nav.toggleCollapsed();
      expect(nav.collapsed, isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 12. NavigationSidebar widget — onNavigate gating
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebar onNavigate gating', () {
    testWidgets('onNavigate fires for a valid leaf', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
      );
      NavNode<String>? navigated;

      await tester.pumpWidget(_wrap(
        Row(children: [
          NavigationSidebar<String>(
            controller: nav,
            mode: NavSidebarMode.expanded,
            onNavigate: (n) => navigated = n,
          ),
          const Expanded(child: SizedBox()),
        ]),
      ));

      // Tap the Approvals leaf
      await tester.tap(find.text('Approvals'));
      await tester.pump();

      expect(navigated, isNotNull);
      expect(navigated!.id, 'approvals');
      nav.dispose();
    });

    testWidgets('onNavigate does NOT fire for a locked node', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
      );
      // First expand Finance to make Wire/SWIFT visible
      nav.expand('financeHub');
      nav.expand('ledgerGroup');
      NavNode<String>? navigated;

      await tester.pumpWidget(_wrap(
        Row(children: [
          NavigationSidebar<String>(
            controller: nav,
            mode: NavSidebarMode.expanded,
            onNavigate: (n) => navigated = n,
          ),
          const Expanded(child: SizedBox()),
        ]),
      ));
      await tester.pump();

      await tester.tap(find.text('Wire / SWIFT'));
      await tester.pump();

      expect(navigated, isNull,
          reason: 'locked node must never trigger onNavigate');
      expect(nav.active, 'dashboard',
          reason: 'active must not change');
      nav.dispose();
    });

    testWidgets('onNavigate does NOT fire for a disabled node',
        (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
      );
      NavNode<String>? navigated;

      await tester.pumpWidget(_wrap(
        Row(children: [
          NavigationSidebar<String>(
            controller: nav,
            mode: NavSidebarMode.expanded,
            onNavigate: (n) => navigated = n,
          ),
          const Expanded(child: SizedBox()),
        ]),
      ));

      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(navigated, isNull,
          reason: 'disabled node must never trigger onNavigate');
      nav.dispose();
    });
  });

  // ════════════════════════════════════════════════════════════
  // 13. NavigationSidebar — drawer mode behavior
  // ════════════════════════════════════════════════════════════
  group('NavigationSidebar drawer mode', () {
    testWidgets('drawer closes after successful navigation', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
        drawerOpen: true,
      );

      await tester.pumpWidget(_wrap(
        Stack(children: [
          const Positioned.fill(child: SizedBox()),
          Positioned.fill(
            child: NavigationSidebar<String>(
              controller: nav,
              mode: NavSidebarMode.drawer,
            ),
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(nav.drawerOpen, isTrue);
      await tester.tap(find.text('Approvals'));
      await tester.pump();
      expect(nav.drawerOpen, isFalse);
      nav.dispose();
    });

    testWidgets('locked node tap does NOT close the drawer', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _basicSections(),
        active: 'dashboard',
        drawerOpen: true,
      );
      nav.expand('financeHub');
      nav.expand('ledgerGroup');

      await tester.pumpWidget(_wrap(
        Stack(children: [
          const Positioned.fill(child: SizedBox()),
          Positioned.fill(
            child: NavigationSidebar<String>(
              controller: nav,
              mode: NavSidebarMode.drawer,
            ),
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wire / SWIFT'));
      await tester.pump();
      // drawer must remain open because navigation was refused
      expect(nav.drawerOpen, isTrue);
      nav.dispose();
    });
  });

  // ════════════════════════════════════════════════════════════
  // 14. NavigationSidebar — search empty state uses localizations
  // ════════════════════════════════════════════════════════════
  testWidgets('search empty state uses localizations.searchEmptyFor',
      (tester) async {
    const customL10n = NavigationSidebarLocalizations(
      searchEmpty: 'Rien pour «\u202f{query}\u202f»',
    );
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
    );

    await tester.pumpWidget(_wrap(
      Row(children: [
        NavigationSidebar<String>(
          controller: nav,
          mode: NavSidebarMode.expanded,
          searchable: true,
          localizations: customL10n,
        ),
        const Expanded(child: SizedBox()),
      ]),
    ));

    await tester.enterText(find.byType(TextField), 'xyzzy');
    await tester.pump();

    expect(find.textContaining('xyzzy'), findsOneWidget);
    expect(find.textContaining('Rien pour'), findsOneWidget);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 15. NavigationSidebar — RTL renders without error
  // ════════════════════════════════════════════════════════════
  testWidgets('sidebar renders in RTL without error', (tester) async {
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
      active: 'dashboard',
    );

    await tester.pumpWidget(_wrap(
      Row(children: [
        NavigationSidebar<String>(
          controller: nav,
          mode: NavSidebarMode.expanded,
          localizations: NavigationSidebarLocalizations.arabic,
        ),
        const Expanded(child: SizedBox()),
      ]),
      rtl: true,
    ));

    expect(tester.takeException(), isNull);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 16. NavigationSidebar — favorites band visible
  // ════════════════════════════════════════════════════════════
  testWidgets('Quick Access band shown when favoritable and favorites exist',
      (tester) async {
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
      active: 'dashboard',
      favorites: {'dashboard'},
    );
    const customL10n = NavigationSidebarLocalizations(
      quickAccessTitle: 'My Pinned',
    );

    await tester.pumpWidget(_wrap(
      Row(children: [
        NavigationSidebar<String>(
          controller: nav,
          mode: NavSidebarMode.expanded,
          favoritable: true,
          localizations: customL10n,
        ),
        const Expanded(child: SizedBox()),
      ]),
    ));

    expect(find.textContaining('MY PINNED'), findsOneWidget);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 17. NavigationSidebarAppBar — drawer mode shows hamburger
  // ════════════════════════════════════════════════════════════
  testWidgets('AppBar in drawer mode shows hamburger that opens drawer',
      (tester) async {
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
    );
    expect(nav.drawerOpen, isFalse);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          extensions: const [NavigationSidebarThemeData.dark]),
      home: Scaffold(
        appBar: NavigationSidebarAppBar(
          controller: nav,
          mode: NavSidebarMode.drawer,
        ),
        body: const SizedBox(),
      ),
    ));

    // Hamburger icon should be present
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    expect(nav.drawerOpen, isTrue);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 18. NavigationSidebarAppBar — expanded mode shows collapse toggle
  // ════════════════════════════════════════════════════════════
  testWidgets('AppBar in expanded mode shows collapse toggle', (tester) async {
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
    );
    expect(nav.collapsed, isFalse);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          extensions: const [NavigationSidebarThemeData.dark]),
      home: Scaffold(
        appBar: NavigationSidebarAppBar(
          controller: nav,
          mode: NavSidebarMode.expanded,
          showCollapseToggle: true,
        ),
        body: const SizedBox(),
      ),
    ));

    // One of the sidebar-view icons should be present
    expect(
      find.byWidgetPredicate((w) =>
          w is Icon &&
          (w.icon == Icons.view_sidebar_outlined ||
              w.icon == Icons.view_sidebar_rounded)),
      findsOneWidget,
    );

    await tester.tap(find.byWidgetPredicate((w) =>
        w is Icon &&
        (w.icon == Icons.view_sidebar_outlined ||
            w.icon == Icons.view_sidebar_rounded)));
    await tester.pump();
    expect(nav.collapsed, isTrue);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 19. NavBreadcrumb — renders ancestor › active label
  // ════════════════════════════════════════════════════════════
  testWidgets('NavBreadcrumb shows ancestor path for active node',
      (tester) async {
    final nav = NavigationSidebarController<String>(
      sections: _basicSections(),
      active: 'journalEntry',
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          extensions: const [NavigationSidebarThemeData.dark]),
      home: Scaffold(
        body: NavBreadcrumb<String>(controller: nav),
      ),
    ));

    // Should contain the active node label
    expect(find.textContaining('Journal Entry'), findsOneWidget);
    nav.dispose();
  });

  // ════════════════════════════════════════════════════════════
  // 20. NavOps utilities
  // ════════════════════════════════════════════════════════════
  group('NavOps', () {
    final sections = _basicSections();

    test('find locates a deeply nested node', () {
      final node = NavOps.find<String>(sections, 'journalEntry');
      expect(node, isNotNull);
      expect(node!.id, 'journalEntry');
    });

    test('find returns null for missing id', () {
      expect(NavOps.find<String>(sections, 'missing'), isNull);
    });

    test('ancestorsOf returns correct path', () {
      final ancestors =
          NavOps.ancestorsOf<String>(sections, 'journalEntry');
      expect(ancestors, containsAll(['financeHub', 'ledgerGroup']));
    });

    test('ancestorsOf returns empty for top-level node', () {
      expect(NavOps.ancestorsOf<String>(sections, 'dashboard'), isEmpty);
    });

    test('subtreeHasBadge', () {
      final root = NavOps.find<String>(sections, 'financeHub')!;
      expect(NavOps.subtreeHasBadge<String>(root), isFalse);
      final approvalsSection = sections.first;
      expect(
        NavOps.subtreeHasBadge<String>(approvalsSection.items.last),
        isTrue,
      );
    });

    test('leafIds collects all leaves under a branch', () {
      final finance = NavOps.find<String>(sections, 'financeHub')!;
      final leaves = NavOps.leafIds<String>(finance);
      expect(leaves, containsAll(['journalEntry', 'wire']));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 21. NavigationSidebarController.canGoBack (2.0)
  // ══════════════════════════════════════════════════════════
  group('NavigationSidebarController.canGoBack', () {
    late NavigationSidebarController<String> nav;
    setUp(() =>
        nav = NavigationSidebarController<String>(sections: _basicSections()));
    tearDown(() => nav.dispose());

    test('defaults to false', () {
      expect(nav.canGoBack, isFalse);
    });

    test('setter updates and notifies once', () {
      int calls = 0;
      nav.addListener(() => calls++);
      nav.canGoBack = true;
      expect(nav.canGoBack, isTrue);
      expect(calls, 1);
      nav.canGoBack = true; // unchanged
      expect(calls, 1);
    });

    test('seeded via constructor', () {
      final n = NavigationSidebarController<String>(
          sections: _basicSections(), canGoBack: true);
      expect(n.canGoBack, isTrue);
      n.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════
  // 22. NavSection placement (2.0)
  // ══════════════════════════════════════════════════════════
  group('NavSection placement', () {
    test('defaults to body', () {
      final s =
          NavSection(title: 'X', items: [NavNode(id: 'a', label: 'A')]);
      expect(s.placement, NavSectionPlacement.body);
    });

    test('footer placement is retained', () {
      final s = NavSection(
        title: 'F',
        placement: NavSectionPlacement.footer,
        items: [NavNode(id: 'set2', label: 'Settings')],
      );
      expect(s.placement, NavSectionPlacement.footer);
    });
  });

  testWidgets('footer section renders a pinned nav item that navigates',
      (tester) async {
    final sections = [
      NavSection(title: 'Main', items: [
        NavNode(id: 'home', label: 'Home', icon: Icons.home, value: 'home'),
      ]),
      NavSection(
        title: '',
        placement: NavSectionPlacement.footer,
        items: [
          NavNode(
              id: 'settingsFooter',
              label: 'Settings',
              icon: Icons.settings,
              value: 'settingsFooter'),
        ],
      ),
    ];
    final nav = NavigationSidebarController<String>(
        sections: sections, active: 'home');
    NavNode<String>? navigated;

    await tester.pumpWidget(_wrap(
      Row(children: [
        NavigationSidebar<String>(
          controller: nav,
          mode: NavSidebarMode.expanded,
          onNavigate: (n) => navigated = n,
        ),
        const Expanded(child: SizedBox()),
      ]),
    ));

    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(navigated?.id, 'settingsFooter');
    nav.dispose();
  });

  // ══════════════════════════════════════════════════════════
  // 23. AppBar back button (2.0)
  // ══════════════════════════════════════════════════════════
  group('NavigationSidebarAppBar back button', () {
    testWidgets('hidden unless showBackButton', (tester) async {
      final nav =
          NavigationSidebarController<String>(sections: _basicSections());
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            extensions: const [NavigationSidebarThemeData.dark]),
        home: Scaffold(
          appBar: NavigationSidebarAppBar(
              controller: nav, mode: NavSidebarMode.expanded),
          body: const SizedBox(),
        ),
      ));
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      nav.dispose();
    });

    testWidgets('enabled tap fires onBack when canGoBack', (tester) async {
      final nav = NavigationSidebarController<String>(
          sections: _basicSections(), canGoBack: true);
      var backs = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            extensions: const [NavigationSidebarThemeData.dark]),
        home: Scaffold(
          appBar: NavigationSidebarAppBar(
            controller: nav,
            mode: NavSidebarMode.expanded,
            showBackButton: true,
            onBack: () => backs++,
          ),
          body: const SizedBox(),
        ),
      ));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(backs, 1);
      nav.dispose();
    });

    testWidgets('disabled does not fire onBack when !canGoBack',
        (tester) async {
      final nav =
          NavigationSidebarController<String>(sections: _basicSections());
      var backs = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            extensions: const [NavigationSidebarThemeData.dark]),
        home: Scaffold(
          appBar: NavigationSidebarAppBar(
            controller: nav,
            mode: NavSidebarMode.expanded,
            showBackButton: true,
            onBack: () => backs++,
          ),
          body: const SizedBox(),
        ),
      ));
      await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
      await tester.pump();
      expect(backs, 0);
      nav.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════
  // 24. NavigationShell (2.0)
  // ══════════════════════════════════════════════════════════
  group('NavigationShell', () {
    testWidgets('spanning layout renders app bar, pane and body',
        (tester) async {
      final nav = NavigationSidebarController<String>(
          sections: _basicSections(), active: 'dashboard');
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            extensions: const [NavigationSidebarThemeData.dark]),
        home: NavigationShell<String>(
          controller: nav,
          mode: NavSidebarMode.expanded,
          appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
              controller: nav, mode: mode, title: const Text('Shell App')),
          sidebarBuilder: (ctx, mode) =>
              NavigationSidebar<String>(controller: nav, mode: mode),
          body: const Text('BODY CONTENT'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Shell App'), findsOneWidget);
      expect(find.text('BODY CONTENT'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      nav.dispose();
    });

    testWidgets('drawer mode wires the hamburger to openDrawer',
        (tester) async {
      final nav =
          NavigationSidebarController<String>(sections: _basicSections());
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            extensions: const [NavigationSidebarThemeData.dark]),
        home: NavigationShell<String>(
          controller: nav,
          mode: NavSidebarMode.drawer,
          appBarBuilder: (ctx, mode) =>
              NavigationSidebarAppBar(controller: nav, mode: mode),
          sidebarBuilder: (ctx, mode) =>
              NavigationSidebar<String>(controller: nav, mode: mode),
          body: const Text('BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('BODY'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      expect(nav.drawerOpen, isTrue);
      nav.dispose();
    });
  });

  testWidgets('bar selection indicator renders without error',
      (tester) async {
    final nav = NavigationSidebarController<String>(
        sections: _basicSections(), active: 'dashboard');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: [
        NavigationSidebarThemeData.dark
            .copyWith(selectionIndicator: NavSelectionIndicator.bar),
      ]),
      home: Scaffold(
        body: Row(children: [
          NavigationSidebar<String>(
              controller: nav, mode: NavSidebarMode.expanded),
          const Expanded(child: SizedBox()),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    nav.dispose();
  });
}
