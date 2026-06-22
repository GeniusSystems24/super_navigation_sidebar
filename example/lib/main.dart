// super_navigation_sidebar · Example app launcher

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

import 'example_01_responsive_shell.dart';
import 'example_02_admin_dashboard.dart';
import 'example_03_theme_rtl.dart';
import 'navigation_sidebar_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'super_navigation_sidebar examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7CFF)),
        extensions: const [NavigationSidebarThemeData.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7CFF),
            brightness: Brightness.dark),
        extensions: const [NavigationSidebarThemeData.dark],
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: LauncherScreen(
          dark: _dark, onToggleTheme: (v) => setState(() => _dark = v)),
    );
  }
}

class LauncherScreen extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggleTheme;
  const LauncherScreen(
      {super.key, required this.dark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    final examples = [
      (
        '01 · Responsive app shell',
        'Device-width simulator: Fill · Desktop · Tablet · Mobile.\n'
            'Expanded / rail / drawer modes with breakpoints.',
        const ResponsiveShellExample(),
      ),
      (
        '02 · Admin dashboard with badges & shortcuts',
        '4 sections, 15+ nodes, NavBadge tones, shortcut hints,\n'
            'deep-link via of(context), live badge update.',
        const AdminDashboardExample(),
      ),
      (
        '03 · Custom theme + RTL + branded colours',
        '3 themes (Dark / Light / Warm), LTR/RTL toggle,\n'
            'showGuides + railFlyouts toggles, copyWith explained.',
        const ThemeRtlExample(),
      ),
      (
        '04 · Full component workbench (original)',
        'Device-width simulator · expanded / rail / drawer · live Light/Dark ·\n'
            'LTR/RTL · command palette · workspace + user menus.',
        const NavigationSidebarDemo(),
      ),
    ];

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        elevation: 0,
        title: Text('super_navigation_sidebar',
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.displayFont,
                fontWeight: FontWeight.w800,
                color: s.fg1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onToggleTheme(!dark),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s.inputBg,
                  border: Border.all(color: s.border),
                  borderRadius: BorderRadius.circular(
                      NavigationSidebarThemeData.radiusMd),
                ),
                child: Row(children: [
                  Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 15,
                      color: s.fg2),
                  const SizedBox(width: 6),
                  Text(dark ? 'Light' : 'Dark',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: s.fg1)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: examples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final ex = examples[i];
          return _ExampleTile(
            title: ex.$1,
            desc: ex.$2,
            onTap: () =>
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => ex.$3)),
          );
        },
      ),
    );
  }
}

class _ExampleTile extends StatefulWidget {
  final String title, desc;
  final VoidCallback onTap;
  const _ExampleTile(
      {required this.title, required this.desc, required this.onTap});
  @override
  State<_ExampleTile> createState() => _ExampleTileState();
}

class _ExampleTileState extends State<_ExampleTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: NavigationSidebarThemeData.durFast,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hover ? s.hover : s.surface,
            border: Border.all(
                color: _hover
                    ? NavigationSidebarThemeData.accent
                    : s.border),
            borderRadius: BorderRadius.circular(
                NavigationSidebarThemeData.radiusLg),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NavigationSidebarThemeData.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(
                    NavigationSidebarThemeData.radiusMd),
              ),
              child: const Icon(Icons.view_sidebar_outlined,
                  size: 20, color: NavigationSidebarThemeData.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.bodyFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: s.fg1)),
                    const SizedBox(height: 4),
                    Text(widget.desc,
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.bodyFont,
                            fontSize: 12.5,
                            height: 1.5,
                            color: s.fg3)),
                  ]),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: s.fg3),
          ]),
        ),
      ),
    );
  }
}
