import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

List<NavSection<String>> _sections() => [
      NavSection<String>(
        title: 'Workspace',
        items: [
          NavNode(
            id: 'dashboard',
            label: 'Dashboard',
            code: 'DB01',
            keywords: const ['overview', 'home'],
            icon: Icons.dashboard_outlined,
            value: 'dashboard',
          ),
          NavNode(
            id: 'finance',
            label: 'Finance',
            icon: Icons.account_balance_outlined,
            children: [
              NavNode(
                id: 'ledger_group',
                label: 'General ledger',
                children: [
                  NavNode(
                    id: 'journals',
                    label: 'Journal entries',
                    code: 'JE01',
                    keywords: const ['voucher', 'posting'],
                    icon: Icons.receipt_long_outlined,
                    badge: const NavBadge('4', tone: NavBadgeTone.warning),
                    value: 'journals',
                  ),
                  NavNode(
                    id: 'locked',
                    label: 'Year-end close',
                    icon: Icons.lock_outline,
                    locked: true,
                    lockMessage: 'Requires Controller role',
                    value: 'locked',
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

List<NavSection<String>> _manySections() => [
      NavSection<String>(
        title: 'Destinations',
        items: [
          for (var i = 0; i < 40; i++)
            NavNode(
              id: 'destination_$i',
              label: 'Destination $i',
              icon: Icons.circle_outlined,
              value: 'destination_$i',
            ),
        ],
      ),
    ];

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          NavigationSidebarThemeData.light,
        ],
      ),
      home: Scaffold(body: child),
    );

void main() {
  group('NavSidebarBreakpoints', () {
    test('maps widths to expanded, rail, and drawer', () {
      const breakpoints = NavSidebarBreakpoints();
      expect(breakpoints.modeFor(1400), NavSidebarMode.expanded);
      expect(breakpoints.modeFor(900), NavSidebarMode.rail);
      expect(breakpoints.modeFor(500), NavSidebarMode.drawer);
    });
  });

  group('NavigationSidebarController', () {
    test('navigates, records recents, and opens ancestors', () {
      final nav = NavigationSidebarController<String>(
        sections: _sections(),
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      expect(nav.navigate('journals'), isTrue);
      expect(nav.active, 'journals');
      expect(nav.activeValue, 'journals');
      expect(nav.recents.first, 'journals');
      expect(nav.isExpanded('finance'), isTrue);
      expect(nav.isExpanded('ledger_group'), isTrue);
    });

    test('refuses locked destinations', () {
      final nav = NavigationSidebarController<String>(sections: _sections());
      addTearDown(nav.dispose);

      expect(nav.navigate('locked'), isFalse);
      expect(nav.active, isNull);
      expect(nav.recents, isEmpty);
    });

    test('tracks favorites', () {
      final nav = NavigationSidebarController<String>(sections: _sections());
      addTearDown(nav.dispose);

      nav.toggleFavorite('journals');
      expect(nav.isFavorite('journals'), isTrue);
      expect(nav.favoriteNodes.map((n) => n.id), contains('journals'));
    });

    test('tree filter matches code and keywords', () {
      final nav = NavigationSidebarController<String>(sections: _sections());
      addTearDown(nav.dispose);

      nav.setQuery('JE01');
      expect(nav.matchSet(), containsAll(<String>['finance', 'ledger_group', 'journals']));

      nav.setQuery('voucher');
      expect(nav.matchSet(), contains('journals'));
    });
  });

  group('NavSearchOps', () {
    test('builds leaf-only index and filters metadata', () {
      final index = NavSearchOps.buildIndex<String>(_sections());
      expect(index.any((hit) => hit.id == 'finance'), isFalse);
      expect(index.any((hit) => hit.id == 'journals'), isTrue);
      expect(NavSearchOps.filter(index, 'JE01').single.id, 'journals');
      expect(NavSearchOps.filter(index, 'voucher').single.id, 'journals');
    });
  });

  group('NavigationSearchView', () {
    testWidgets('renders and filters results', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _sections(),
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 520,
            child: NavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Journal entries'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('navigation-search-input')),
        'JE01',
      );
      await tester.pump();

      expect(find.text('Journal entries'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('keyboard navigation scrolls selected result into view',
        (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _manySections(),
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 320,
            child: NavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
              showKeyboardHints: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('navigation-search-input')));
      await tester.pump();

      for (var i = 0; i < 24; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      final selected = find.text('Destination 24');
      expect(selected, findsOneWidget);

      final viewRect =
          tester.getRect(find.byType(NavigationSearchView<String>));
      final selectedRect = tester.getRect(selected);
      expect(selectedRect.top, greaterThanOrEqualTo(viewRect.top));
      expect(selectedRect.bottom, lessThanOrEqualTo(viewRect.bottom));

      for (var i = 0; i < 24; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      final first = find.text('Destination 0');
      expect(first, findsOneWidget);
      final firstRect = tester.getRect(first);
      expect(firstRect.top, greaterThanOrEqualTo(viewRect.top));
      expect(firstRect.bottom, lessThanOrEqualTo(viewRect.bottom));
    });

    testWidgets('picking a result navigates when no callback is supplied',
        (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _sections(),
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 520,
            child: NavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Journal entries'));
      await tester.pump();
      expect(nav.active, 'journals');
    });

    testWidgets('dialog and sheet presenters open the same search view',
        (tester) async {
      final nav = NavigationSidebarController<String>(sections: _sections());
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showNavigationSearchView<String>(
                    context,
                    controller: nav,
                    mode: NavigationSearchViewMode.dialog,
                  ),
                  child: const Text('dialog'),
                ),
                TextButton(
                  onPressed: () => showNavigationSearchView<String>(
                    context,
                    controller: nav,
                    mode: NavigationSearchViewMode.sheet,
                  ),
                  child: const Text('sheet'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationSearchView<String>), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationSearchView<String>), findsOneWidget);
    });
  });

  group('NavigationSidebar', () {
    testWidgets('renders current 3.0 API', (tester) async {
      final nav = NavigationSidebarController<String>(
        sections: _sections(),
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          NavigationSidebar<String>(
            controller: nav,
            mode: NavSidebarMode.expanded,
            showPaneToggle: true,
            allowSearchView: true,
            searchViewMode: NavigationSearchViewMode.dialog,
            favoritable: true,
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);
    });
  });
}
