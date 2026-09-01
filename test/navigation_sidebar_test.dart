import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

List<SuperNavSection<String>> _sections() => [
  SuperNavSection<String>(
    title: 'Workspace',
    items: [
      SuperNavNode(
        id: 'dashboard',
        label: const Text('Dashboard'),
        code: 'DB01',
        keywords: const ['overview', 'home'],
        leadingIcon: const Icon(Icons.dashboard_outlined),
        value: 'dashboard',
      ),
      SuperNavNode(
        id: 'finance',
        label: const Text('Finance'),
        leadingIcon: const Icon(Icons.account_balance_outlined),
        children: [
          SuperNavNode(
            id: 'ledger_group',
            label: const Text('General ledger'),
            children: [
              SuperNavNode(
                id: 'journals',
                label: const Text('Journal entries'),
                code: 'JE01',
                keywords: const ['voucher', 'posting'],
                leadingIcon: const Icon(Icons.receipt_long_outlined),
                badge: const SuperNavBadge(
                  '4',
                  tone: SuperNavBadgeTone.warning,
                ),
                value: 'journals',
              ),
              SuperNavNode(
                id: 'locked',
                label: const Text('Year-end close'),
                leadingIcon: const Icon(Icons.lock_outline),
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
  SuperNavSection<String>(
    title: 'System',
    placement: SuperNavSectionPlacement.footer,
    items: [
      SuperNavNode(
        id: 'settings',
        label: const Text('Settings'),
        leadingIcon: const Icon(Icons.settings_outlined),
        value: 'settings',
      ),
    ],
  ),
];

List<SuperNavSection<String>> _manySections() => [
  SuperNavSection<String>(
    title: 'Destinations',
    items: [
      for (var i = 0; i < 40; i++)
        SuperNavNode(
          id: 'destination_$i',
          label: Text('Destination $i'),
          leadingIcon: const Icon(Icons.circle_outlined),
          value: 'destination_$i',
        ),
    ],
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      SuperNavigationSidebarThemeData.light,
    ],
  ),
  home: Scaffold(body: child),
);

void main() {
  group('SuperNavSidebarBreakpoints', () {
    test('maps widths to expanded, rail, and drawer', () {
      const breakpoints = SuperNavSidebarBreakpoints();
      expect(breakpoints.modeFor(1400), SuperNavSidebarMode.expanded);
      expect(breakpoints.modeFor(900), SuperNavSidebarMode.rail);
      expect(breakpoints.modeFor(500), SuperNavSidebarMode.drawer);
    });
  });

  group('SuperNavigationSidebarController', () {
    test('navigates, records recents, and opens ancestors', () {
      final nav = SuperNavigationSidebarController<String>(
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
      final nav = SuperNavigationSidebarController<String>(
        sections: _sections(),
      );
      addTearDown(nav.dispose);

      expect(nav.navigate('locked'), isFalse);
      expect(nav.active, isNull);
      expect(nav.recents, isEmpty);
    });

    test('tracks favorites', () {
      final nav = SuperNavigationSidebarController<String>(
        sections: _sections(),
      );
      addTearDown(nav.dispose);

      nav.toggleFavorite('journals');
      expect(nav.isFavorite('journals'), isTrue);
      expect(nav.favoriteNodes.map((n) => n.id), contains('journals'));
    });

    test('tree filter matches code and keywords', () {
      final nav = SuperNavigationSidebarController<String>(
        sections: _sections(),
      );
      addTearDown(nav.dispose);

      nav.setQuery('JE01');
      expect(
        nav.matchSet(),
        containsAll(<String>['finance', 'ledger_group', 'journals']),
      );

      nav.setQuery('voucher');
      expect(nav.matchSet(), contains('journals'));
    });
  });

  group('SuperNavSearchOps', () {
    test('builds leaf-only index and filters metadata', () {
      final index = SuperNavSearchOps.buildIndex<String>(_sections());
      expect(index.any((hit) => hit.id == 'finance'), isFalse);
      expect(index.any((hit) => hit.id == 'journals'), isTrue);
      expect(SuperNavSearchOps.filter(index, 'JE01').single.id, 'journals');
      expect(SuperNavSearchOps.filter(index, 'voucher').single.id, 'journals');
    });
  });

  group('SuperNavigationSearchView', () {
    testWidgets('renders and filters results', (tester) async {
      final nav = SuperNavigationSidebarController<String>(
        sections: _sections(),
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 520,
            child: SuperNavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Journal entries'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'JE01');
      await tester.pump();

      expect(find.text('Journal entries'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('keyboard navigation scrolls selected result into view', (
      tester,
    ) async {
      final nav = SuperNavigationSidebarController<String>(
        sections: _manySections(),
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 320,
            child: SuperNavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
              showKeyboardHints: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(EditableText));
      await tester.pump();

      for (var i = 0; i < 24; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      final selected = find.text('Destination 24');
      expect(selected, findsOneWidget);

      final viewRect = tester.getRect(
        find.byType(SuperNavigationSearchView<String>),
      );
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

    testWidgets('picking a result navigates when no callback is supplied', (
      tester,
    ) async {
      var tapped = false;
      final nav = SuperNavigationSidebarController<String>(
        sections: [
          SuperNavSection<String>(
            title: 'Workspace',
            items: [
              SuperNavNode(
                id: 'dashboard',
                label: const Text('Dashboard'),
                leadingIcon: const Icon(Icons.dashboard_outlined),
                value: 'dashboard',
              ),
              SuperNavNode(
                id: 'journals',
                label: const Text('Journal entries'),
                leadingIcon: const Icon(Icons.receipt_long_outlined),
                value: 'journals',
                onTap: (_) => tapped = true,
              ),
            ],
          ),
        ],
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 520,
            child: SuperNavigationSearchView<String>(
              controller: nav,
              autofocus: false,
              closeOnPick: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journal entries'));
      await tester.pump();
      expect(nav.active, 'journals');
      expect(tapped, isTrue);
    });

    testWidgets('dialog and sheet presenters open the same search view', (
      tester,
    ) async {
      final nav = SuperNavigationSidebarController<String>(
        sections: _sections(),
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showSuperNavigationSearchView<String>(
                    context,
                    controller: nav,
                    mode: SuperNavigationSearchViewMode.dialog,
                  ),
                  child: const Text('dialog'),
                ),
                TextButton(
                  onPressed: () => showSuperNavigationSearchView<String>(
                    context,
                    controller: nav,
                    mode: SuperNavigationSearchViewMode.sheet,
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
      expect(find.byType(SuperNavigationSearchView<String>), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(SuperNavigationSearchView<String>), findsOneWidget);
    });
  });

  group('SuperNavigationSidebar', () {
    testWidgets('renders current 3.3 API and invokes node onTap', (
      tester,
    ) async {
      var tapped = false;
      final nav = SuperNavigationSidebarController<String>(
        sections: [
          SuperNavSection<String>(
            title: 'Workspace',
            items: [
              SuperNavNode(
                id: 'dashboard',
                label: const Text('Dashboard'),
                leadingIcon: const Icon(Icons.dashboard_outlined),
                value: 'dashboard',
              ),
              SuperNavNode(
                id: 'journals',
                label: const Text('Journal entries'),
                leadingIcon: const Icon(Icons.receipt_long_outlined),
                value: 'journals',
                onTap: (_) => tapped = true,
              ),
            ],
          ),
        ],
        active: 'dashboard',
      );
      addTearDown(nav.dispose);

      await tester.pumpWidget(
        _app(
          SuperNavigationSidebar<String>(
            controller: nav,
            mode: SuperNavSidebarMode.expanded,
            showPaneToggle: true,
            allowSearchView: true,
            searchViewMode: SuperNavigationSearchViewMode.dialog,
            favoritable: true,
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);

      await tester.tap(find.text('Journal entries'));
      await tester.pump();
      expect(nav.active, 'journals');
      expect(tapped, isTrue);
    });
  });
}
