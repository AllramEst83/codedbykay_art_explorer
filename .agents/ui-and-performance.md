# UI and performance

- Material 3, light/dark/system, dynamic color on Android 12+. Colors and text styles come from `Theme.of(context)`; no hard-coded colors outside the reader themes.
- Split into small `const` widget classes rather than helper methods returning widgets.
- Lists/grids are lazy (`SliverGrid`, `ListView.builder`); never build all items.
- Images: use `CachedNetworkImage` with `memCacheWidth` sized to the layout; always provide placeholder + error widget.
- No work in `build`: no parsing, sorting, network. Use `select` on providers to limit rebuilds.
- Respect system text scale and safe areas; layouts must not overflow at 200% font scale or on tablets.
- Profile before adding `RepaintBoundary` or other optimisations.
