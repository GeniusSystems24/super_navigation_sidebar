# NavigationView conformance review — `super_navigation_sidebar`

**Scope:** compare the library against Microsoft's
[NavigationView guidelines](https://learn.microsoft.com/en-us/windows/apps/design/controls/navigationview),
with an emphasis on how the **AppBar integrates with the SideBar**, and land the
gaps in **2.0.0**.

---

## 1. What NavigationView prescribes (the parts that matter here)

| Area | NavigationView behavior |
|---|---|
| **Display modes** | `Left` (expanded, side-by-side), `LeftCompact` (icon rail; opening **overlays** content), `LeftMinimal` (menu button only; pane overlays), `Top`, and `Auto` (adapts by width: ≥1008 Left · 641–1007 Compact · ≤640 Minimal). |
| **Pane anatomy** | Menu (pane-toggle) button + **back button in the top-left corner of the pane**, nav items, separators, headers, `AutoSuggestBox`, **FooterMenuItems**, a Settings entry point, `PaneTitle` / `PaneHeader` / `PaneFooter`. |
| **Header / content** | A page-title **header band** (~52 px) that is *vertically aligned with the nav button*, docked to the top; content margins 12 px (minimal) / 24 px otherwise. |
| **Selection** | A single **selection indicator** drawn on the item's **leading edge** (left mode); collapses to the first visible ancestor. |
| **Back nav** | `IsBackButtonVisible` / `IsBackEnabled` / `BackRequested`; enablement bound to the frame's `CanGoBack`. |
| **Title-bar integration** ⭐ | The **recommended** pattern (WinUI Gallery) puts a **`TitleBar` spanning the full width above the NavigationView**; the title bar **owns the back button + pane toggle** and forwards them to the nav. The nav hides its built-ins. The result is one integrated "L": bar across the top, pane down the left, and the toggle/back in the shared top-left corner directly **over the pane**. |

---

## 2. Gap analysis (1.2.x)

The data model, three modes, theming, search, badges, locking, a11y and RTL were
already strong. The gaps clustered exactly where the brief pointed — the
**AppBar ↔ SideBar seam**:

1. **No integrated layout.** `NavigationSidebarAppBar` and `NavigationSidebar`
   were composed by hand (`Row` / `Column` / `Stack`) in every host. In the
   desktop example the bar was nested *to the right of* the pane, so it **did not
   span the top**, and its toggle did **not** align over the pane — the opposite
   of the WinUI-Gallery "L". This is the single biggest divergence.
2. **No back button** anywhere — no `IsBackButtonVisible` / `IsBackEnabled`
   analogue, and no top-left placement.
3. **Collapse always pushed content.** No **overlay** (LeftCompact/Minimal)
   behavior where opening the pane floats over content without reflowing it.
4. **No footer nav items.** Only a free-form `footer` slot; nothing equivalent to
   `FooterMenuItems` (Settings/Help pinned to the bottom, in the selection model).
5. **No top-of-pane menu button.** The toggle lived only in the app bar.
6. **Selection = full fill**, not the Fluent leading-edge indicator pill.
7. **No formal content header / margins** contract.

---

## 3. Recommendations → what shipped in 2.0.0

All additive; no breaking changes from 1.2.x.

### 3.1 `NavigationShell<T>` — the integrated scaffold *(headline)*
One widget composes **app bar + pane + content** in the correct arrangement, so
hosts stop hand-wiring layout.
- **`headerLayout: spanning`** (default) — full-width bar across the top with the
  pane below it; the bar's leading zone (back + toggle) lands **directly over the
  pane** → the WinUI-Gallery "L". `inset` keeps the pane full-height with the bar
  above content only.
- **`paneBehavior: push | overlay`** — `push` reflows content (Left); `overlay`
  keeps a rail in-flow and floats the full pane over content with an animated
  scrim (LeftCompact/Minimal).
- **Adaptive** by `NavSidebarBreakpoints`, or a fixed `mode`; NavigationView's
  **content margins** (24/12 px) applied via `contentPadding`. Drawer mode wires
  the hamburger + off-canvas overlay automatically.

### 3.2 Back button
- `NavigationSidebarController.canGoBack` (bind to your router's can-pop, à la
  `IsBackEnabled`).
- `NavigationSidebarAppBar.showBackButton` + `onBack` — renders in the
  **top-left corner**, enabled only while `canGoBack`, RTL-mirrored, with a
  `semanticBack` label.

### 3.3 Footer navigation items (`FooterMenuItems`)
- `NavSection.placement: NavSectionPlacement.footer` pins a band to the pane
  bottom in **both** expanded and rail modes, sharing the **one selection
  model** (active highlight, breadcrumbs, search, `navigate()`).

### 3.4 Fluent selection indicator
- `NavigationSidebarThemeData.selectionIndicator: NavSelectionIndicator.bar`
  draws a leading accent **pill** (tree + rail), tunable via `indicatorThickness`
  / `indicatorInset`. `fill` remains the default (unchanged look).

### 3.5 Top-of-pane menu button
- `NavigationSidebar.showPaneToggle` renders the collapse/expand button pinned to
  the top of the pane — the NavigationView "menu button" placement — for
  inset-header shells where the bar doesn't sit over the pane.

### 3.6 Misc
- `headerHeight` (52) token; new enums + `NavShellSlotBuilder` exported;
  **Example 06 · Integrated NavigationShell** with live toggles for every axis.

---

## 4. Alignment / visual-consistency notes

- In **spanning** layout the bar and pane share the same `surface` + `border`
  tokens, and the bar's bottom hairline meets the pane's trailing hairline at the
  top-left corner — one continuous frame.
- The back button and pane toggle use the same `toolbarButtonSize` /
  `toolbarIconSize` and sit in the bar's leading zone, lining up over the pane
  width — matching the reference (WinUI 3 Gallery).
- The `bar` indicator matches the reference's selected-rail treatment (leading
  pill on a tinted button) instead of a solid fill.

---

## 5. Deliberately deferred (candidates for later)

- **`Top` display mode** (horizontal nav) — large surface; out of scope for a
  side-navigation package.
- **Hierarchical keyboard "inner navigation"** (arrow-key tree traversal within
  the pane) — current a11y covers Enter/Space activation + focus traversal.
- **Real title-bar / window drag-region** integration (`ExtendsContentIntoTitleBar`)
  — platform-specific; the shell leaves the OS title bar to the host.
- **Auto-collapse-to-ancestor selection indicator** when a selected child's
  subtree is collapsed (NavigationView shows the indicator on the first visible
  ancestor). `ownsActive` already tints the ancestor; a moving indicator is a
  possible refinement.
