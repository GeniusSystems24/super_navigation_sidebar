// ============================================================
// NavigationSidebar — SHORTCUT BINDER.
// ------------------------------------------------------------
// Turns NavNode.shortcut declarations from *visual hints* into *working
// keystrokes*. Wrap any part of the app (typically the NavigationShell or
// the Scaffold body) in a NavShortcutBinder and every leaf node that
// declares a shortcut becomes activatable from the keyboard.
//
// Two shortcut styles are supported, chosen per node by its key list:
//
//   • Modifier combo  ['ctrl', 'shift', 'd']  →  Ctrl+Shift+D pressed together.
//     Any of ctrl/control · shift · alt/option · cmd/meta/super/win may be
//     combined with exactly one main key. Matched on the main key's KeyDown
//     with the exact modifier set held.
//   • Sequential chord ['g', 'd']  →  the classic "type g then d" pattern,
//     matched key-by-key with a rolling buffer and a timeout between keys.
//
//   NavShortcutBinder<String>(
//     controller: _nav,
//     onNavigate: (n) => setState(() => _screen = n.value!),
//     child: NavigationShell<String>(...),
//   )
//
// Behaviour:
//   • Single-key shortcuts (['j'] or ['ctrl','k']) work too.
//   • Keys are ignored while the user is typing in any text field
//     (EditableText has primary focus), so shortcuts never eat form input.
//   • Locked / disabled nodes are refused by the controller as usual —
//     onNavigate only fires when navigation is actually applied.
//   • The shortcut map rebuilds automatically when the controller's sections
//     are hot-swapped (replaceSections).
//
// The binder listens via HardwareKeyboard.instance so it works regardless
// of where focus is — no FocusNode plumbing needed in the host app.
//
//   File: lib/src/shortcut_binder.dart
// ============================================================

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'controller.dart';
import 'models.dart';

/// Registers every [NavNode.shortcut] on [controller]'s tree as a working
/// keyboard shortcut and navigates when one is typed.
///
/// Supports both `['ctrl', 'shift', 'd']` modifier combos and `['g', 'd']`
/// sequential chords — the style is chosen per node from its key list. Place
/// once, high in the tree (around the shell). Shortcuts are suspended while a
/// text field has focus.
class NavShortcutBinder<T> extends StatefulWidget {
  /// The controller whose tree supplies the shortcuts and receives navigation.
  final NavigationSidebarController<T> controller;

  /// Called after a shortcut successfully navigates (mirror of
  /// [NavigationSidebar.onNavigate]). Locked / disabled nodes never fire it.
  final ValueChanged<NavNode<T>>? onNavigate;

  /// Maximum pause between the keys of a *sequential* chord. Default: 1200 ms.
  /// (Modifier combos are instantaneous and ignore this.)
  final Duration chordTimeout;

  /// Set `false` to suspend all shortcuts (e.g. while a modal wizard is open).
  final bool enabled;

  final Widget child;

  const NavShortcutBinder({
    super.key,
    required this.controller,
    required this.child,
    this.onNavigate,
    this.chordTimeout = const Duration(milliseconds: 1200),
    this.enabled = true,
  });

  @override
  State<NavShortcutBinder<T>> createState() => _NavShortcutBinderState<T>();
}

/// A parsed modifier combo (e.g. Ctrl+Shift+D).
class _NavCombo {
  final NavNodeId id;
  final bool ctrl, shift, alt, meta;
  final String key; // lowercased main key char
  const _NavCombo(
    this.id, {
    required this.ctrl,
    required this.shift,
    required this.alt,
    required this.meta,
    required this.key,
  });
}

class _NavShortcutBinderState<T> extends State<NavShortcutBinder<T>> {
  /// Sequential chords: 'g d' → node id.
  Map<String, NavNodeId> _sequences = const {};

  /// Modifier combos (Ctrl+Shift+D …).
  List<_NavCombo> _combos = const [];

  final List<String> _buffer = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _rebuild();
    widget.controller.addListener(_rebuild);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(covariant NavShortcutBinder<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
      _rebuild();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    final seq = <String, NavNodeId>{};
    final combos = <_NavCombo>[];
    NavOps.walk<T>(widget.controller.sections, (n, _) {
      final sc = n.shortcut;
      if (!n.isLeaf || sc == null || sc.isEmpty) return;
      if (NavShortcutOps.isCombo(sc)) {
        final c = _parseCombo(n.id, sc);
        if (c != null) combos.add(c);
      } else {
        seq[sc.map((k) => k.toLowerCase()).join(' ')] = n.id;
      }
    });
    _sequences = seq;
    _combos = combos;
  }

  _NavCombo? _parseCombo(NavNodeId id, List<String> keys) {
    var ctrl = false, shift = false, alt = false, meta = false;
    String? main;
    for (final raw in keys) {
      switch (raw.toLowerCase()) {
        case 'ctrl':
        case 'control':
          ctrl = true;
          break;
        case 'shift':
          shift = true;
          break;
        case 'alt':
        case 'option':
          alt = true;
          break;
        case 'cmd':
        case 'meta':
        case 'super':
        case 'win':
          meta = true;
          break;
        default:
          main = raw.toLowerCase(); // last non-modifier is the main key
      }
    }
    if (main == null || main.isEmpty) return null;
    return _NavCombo(
      id,
      ctrl: ctrl,
      shift: shift,
      alt: alt,
      meta: meta,
      key: main,
    );
  }

  /// True while an editable text field owns primary focus — shortcuts must not
  /// steal characters from form input.
  bool get _typing {
    final focused = FocusManager.instance.primaryFocus?.context?.widget;
    return focused is EditableText;
  }

  /// The main (non-modifier) character of a key event, lowercased, or null.
  String? _mainKeyChar(KeyEvent e) {
    final label = e.logicalKey.keyLabel;
    if (label.length == 1) return label.toLowerCase();
    final ch = e.character;
    if (ch != null && ch.length == 1 && ch.trim().isNotEmpty) {
      return ch.toLowerCase();
    }
    return null;
  }

  void _fire(NavNodeId id) {
    if (widget.controller.navigate(id)) {
      final n = widget.controller.node(id);
      if (n != null) widget.onNavigate?.call(n);
    }
  }

  void _reset() {
    _timer?.cancel();
    _buffer.clear();
  }

  bool _onKey(KeyEvent event) {
    if (!widget.enabled) return false;
    if (event is! KeyDownEvent) return false;
    if (_typing) return false;
    final hk = HardwareKeyboard.instance;
    final mainKey = _mainKeyChar(event);

    // 1) Modifier combos (Ctrl+Shift+D) — matched on the main key's press.
    if (_combos.isNotEmpty && mainKey != null) {
      for (final c in _combos) {
        if (c.key == mainKey &&
            c.ctrl == hk.isControlPressed &&
            c.shift == hk.isShiftPressed &&
            c.alt == hk.isAltPressed &&
            c.meta == hk.isMetaPressed) {
          _reset();
          _fire(c.id);
          return true;
        }
      }
    }

    // 2) Sequential chords (g then d) — only when NO modifiers are held, so
    //    they never collide with combos or host-app Ctrl/Cmd shortcuts.
    if (_sequences.isEmpty) return false;
    if (hk.isControlPressed || hk.isMetaPressed || hk.isAltPressed) {
      _reset();
      return false;
    }
    if (mainKey == null) return false;

    _buffer.add(mainKey);
    final joined = _buffer.join(' ');

    final id = _sequences[joined];
    if (id != null) {
      _reset();
      _fire(id);
      return true;
    }

    // Keep buffering only while it still prefixes some chord.
    final isPrefix = _sequences.keys.any((c) => c.startsWith('$joined '));
    if (!isPrefix) {
      _reset();
      // The key itself may complete or start a new chord.
      final single = _sequences[mainKey];
      if (single != null) {
        _fire(single);
        return true;
      }
      if (_sequences.keys.any((c) => c.startsWith('$mainKey '))) {
        _buffer.add(mainKey);
      } else {
        return false;
      }
    }
    _timer?.cancel();
    _timer = Timer(widget.chordTimeout, _reset);
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
