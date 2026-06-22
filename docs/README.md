# super_navigation_sidebar · docs

Reference documentation for the `super_navigation_sidebar` Flutter package.

For the interactive live gallery, open
`../../geniuslink_design_system_flutter/docs/components-navigation-sidebar.html`
in a browser.

---

## Mode anatomy

```
Expanded (≥ 1200 px)                Rail (≥ 768 px)    Drawer (< 768 px)
┌──────────────────┬──────────────┐  ┌────┬──────────┐  ┌──────────────┐
│ ⬡ GeniusLink     │   Page       │  │ 🏠 │  Page    │  │    Page      │
│                  │              │  │ 📋 │          │  │              │
│ OVERVIEW         │              │  │ ⚙️ │          │  │  ┌────────┐  │
│  ● Dashboard     │              │  │    │          │  │  │  Nav   │  │
│                  │              │  │    │          │  │  │ Drawer │  │
│ FINANCE          │              │  │    │          │  │  └────────┘  │
│  ▸ Accounts      │              │  │    │          │  │   (scrim)    │
│    ├─ Chart…     │              │  │    │          │  └──────────────┘
│    └─ Tree  [3]  │              │  │    │          │  open via
│  ▸ Ledger        │              │  │    │          │  nav.openDrawer()
│    └─ JE…[Live]  │              │  │    │          │
└──────────────────┴──────────────┘  └────┴──────────┘
    248 px                               76 px              280 px
```

---

## Node role reference

| Depth | Has children | Role | Visual |
|---|---|---|---|
| 0 | No | `direct` | Full-width pill; fills accent when active. |
| 0 | Yes | `module` | Icon + label + chevron; accent-tinted when owning active. Badge collapses to a dot on rail/collapsed. |
| ≥1 | Yes | `group` | Uppercase bullet header inside a module. |
| ≥1 | No | `item` | Boxed icon (28 × 28 px) + label. Accent-fill box + border when active. |

---

## `NavBadge` tone reference

| Tone | Colour | Typical use |
|---|---|---|
| `accent` (default) | `#4A7CFF` blue | Count, notification. |
| `success` | `#1DB88A` green | Live / synced status. |
| `warning` | `#F97316` orange | Pending / attention. |
| `muted` | `fg3` grey | Secondary count, low priority. |

On expanded rows: pill (text inside a rounded container).
On collapsed modules / rail icons: 7 px dot overlaid on the icon's top-end corner.

---

## `NavigationSidebarThemeData` token reference

### Instance fields (lerped between dark & light)

| Field | Dark | Light | Purpose |
|---|---|---|---|
| `bg` | `#111318` | `#F7F8FA` | Page backdrop the sidebar floats over. |
| `surface` | `#1E2025` | `#FFFFFF` | Sidebar panel fill. |
| `inputBg` | `#33353A` | `#F1F3F8` | Boxed-icon fill / chip backgrounds. |
| `hover` | `#2F3540` | `#EEF1F7` | Row hover tint. |
| `border` | `rgba(67,70,84,.4)` | `#E2E8F0` | Hairline dividers. |
| `borderStrong` | `#434654` | `#C2C6D6` | Outer frame / flyout card edge. |
| `guide` | `#434654` | `#C2C6D6` | `│ ├ └` connector line colour. |
| `fg1` | `#E2E2E9` | `#0F172A` | Active label / primary text. |
| `fg2` | `#C3C6D7` | `#424754` | Row label (inactive). |
| `fg3` | `#8D90A0` | `#64748B` | Icons, group labels, chevrons. |
| `fg4` | `#44474E` | `#C2C6D6` | Section eyebrows, disabled. |

### Brand constants (theme-independent statics)

| Token | Value | Usage |
|---|---|---|
| `accent` | `#4A7CFF` | Active rows, module tint, boxed icon border. |
| `success` | `#1DB88A` | Badge success tone. |
| `warning` | `#F97316` | Badge warning tone. |
| `danger` | `#EF4444` | Badge danger tone. |
| `displayFont` | `'Manrope'` | Wordmark / headings. |
| `bodyFont` | `'Inter'` | Row labels, section titles. |
| `monoFont` | `'JetBrainsMono'` | Shortcut hints, eyebrows. |
| `widthExpanded` | `248 px` | Expanded sidebar width. |
| `widthRail` | `76 px` | Rail width. |
| `widthDrawer` | `280 px` | Drawer width. |
| `railButton` | `44 px` | Rail icon button size. |
| `directHeight` | `42 px` | Direct-destination row height. |
| `moduleHeight` | `42 px` | Module row height. |
| `groupHeight` | `36 px` | Group header row height. |
| `itemHeight` | `38 px` | Item row height. |
| `durFast` | `150 ms` | Hover tints. |
| `durBase` | `240 ms` | Expansion, chevron rotation. |
| `durDrawer` | `280 ms` | Drawer slide / scrim fade. |

---

## Exported symbols

| Symbol | Kind | Description |
|---|---|---|
| `NavigationSidebar<T>` | Widget | Main sidebar widget. |
| `NavigationSidebarController<T>` | ChangeNotifier | State + all operations. |
| `NavigationSidebarScope<T>` | InheritedNotifier | Exposes controller to descendants. |
| `NavigationSidebarThemeData` | ThemeExtension | All theme tokens + helpers. |
| `NavSection<T>` | Class | `title` + `List<NavNode<T>>`. |
| `NavNode<T>` | Class | Node model (id · label · icon · children · value · badge · shortcut · enabled). |
| `NavNodeRole` | Enum | `direct · module · group · item`. |
| `NavBadge` | Class | Badge model (`text` + `NavBadgeTone`). |
| `NavBadgeTone` | Enum | `accent · success · warning · muted`. |
| `NavNodeId` | Typedef | `String` — node identity. |
| `NavSidebarMode` | Enum | `expanded · rail · drawer`. |
| `NavSidebarBreakpoints` | Class | `modeFor(width)` helper. |
| `NavSidebarSlotBuilder` | Typedef | `Widget Function(BuildContext, bool collapsed)`. |
| `NavOps` | Class | `walk · find · ancestorsOf · subtreeHasBadge · leafIds`. |
