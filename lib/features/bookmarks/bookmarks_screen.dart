import 'package:codedbykay_art_explorer/core/widgets/art_image.dart';
import 'package:codedbykay_art_explorer/core/widgets/artwork_card.dart';
import 'package:codedbykay_art_explorer/core/widgets/state_views.dart';
import 'package:codedbykay_art_explorer/features/bookmarks/bookmarks_controller.dart';
import 'package:codedbykay_art_explorer/features/search/paged_artwork_view.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookmarkSort {
  newest,
  oldest,
  title;

  String label(AppLocalizations l) => switch (this) {
    newest => l.sortNewest,
    oldest => l.sortOldest,
    title => l.sortTitle,
  };
}

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  bool _grid = true;
  String _filter = '';
  String? _collection;
  BookmarkSort _sort = BookmarkSort.newest;

  List<Bookmark> _visible(List<Bookmark> all) {
    final q = _filter.toLowerCase();
    final list = [
      for (final b in all)
        if ((_collection == null || b.collection == _collection) &&
            (q.isEmpty ||
                b.artwork.title.toLowerCase().contains(q) ||
                b.artwork.creators.any((c) => c.toLowerCase().contains(q))))
          b,
    ];
    switch (_sort) {
      case BookmarkSort.newest:
        list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      case BookmarkSort.oldest:
        list.sort((a, b) => a.savedAt.compareTo(b.savedAt));
      case BookmarkSort.title:
        list.sort(
          (a, b) => a.artwork.title.toLowerCase().compareTo(
            b.artwork.title.toLowerCase(),
          ),
        );
    }
    return list;
  }

  void _remove(Bookmark b) {
    ref.read(bookmarksProvider.notifier).toggle(b.artwork);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.bookmarkRemoved),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => ref.read(bookmarksProvider.notifier).restore(b),
          ),
        ),
      );
  }

  Future<void> _assignCollection(Bookmark b, List<Bookmark> all) async {
    final existing = {
      for (final x in all)
        if (x.collection != null) x.collection!,
    }.toList()..sort();
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.addToCollection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final c in existing)
                  ActionChip(
                    label: Text(c),
                    onPressed: () => Navigator.pop(context, c),
                  ),
              ],
            ),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: context.l10n.newCollection,
              ),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
          ],
        ),
        actions: [
          if (b.collection != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(context.l10n.removeFromCollection),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    ref
        .read(bookmarksProvider.notifier)
        .setCollection(b.artwork.key, result.isEmpty ? null : result);
  }

  void _showActions(Bookmark b, List<Bookmark> all) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(context.l10n.addToCollection),
              onTap: () {
                Navigator.pop(context);
                _assignCollection(b, all);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_remove_outlined),
              title: Text(context.l10n.removeBookmark),
              onTap: () {
                Navigator.pop(context);
                _remove(b);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(bookmarksProvider);
    final visible = _visible(all);
    final collections = {
      for (final b in all)
        if (b.collection != null) b.collection!,
    }.toList()..sort();
    final width = MediaQuery.sizeOf(context).width;
    final columns = gridColumns(width);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bookmarksTitle),
        actions: [
          PopupMenuButton<BookmarkSort>(
            tooltip: context.l10n.sort,
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in BookmarkSort.values)
                PopupMenuItem(value: s, child: Text(s.label(context.l10n))),
            ],
          ),
          IconButton(
            tooltip: _grid ? context.l10n.listView : context.l10n.gridView,
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
      ),
      body: all.isEmpty
          ? EmptyView(
              icon: Icons.bookmark_border,
              title: context.l10n.noBookmarks,
              subtitle: context.l10n.noBookmarksHint,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    hintText: context.l10n.searchBookmarks,
                    leading: const Icon(Icons.search),
                    onChanged: (v) => setState(() => _filter = v.trim()),
                  ),
                ),
                if (collections.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(context.l10n.all),
                            selected: _collection == null,
                            onSelected: (_) =>
                                setState(() => _collection = null),
                          ),
                        ),
                        for (final c in collections)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(c),
                              selected: _collection == c,
                              onSelected: (_) => setState(
                                () => _collection = _collection == c ? null : c,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyView(
                          icon: Icons.search_off,
                          title: context.l10n.noMatchingBookmarks,
                        )
                      : _grid
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onLongPress: () => _showActions(visible[i], all),
                            child: ArtworkCard(
                              artwork: visible[i].artwork,
                              width: width / columns,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (_, i) {
                            final b = visible[i];
                            return Dismissible(
                              key: ValueKey(b.artwork.key),
                              direction: DismissDirection.endToStart,
                              background: ColoredBox(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 24),
                                    child: Icon(Icons.delete_outline),
                                  ),
                                ),
                              ),
                              onDismissed: (_) => _remove(b),
                              child: ListTile(
                                leading: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ArtImage(
                                      url: b.artwork.thumbnailUrl,
                                      memCacheWidth: 168,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  b.artwork.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (b.artwork.creators.isNotEmpty)
                                      b.artwork.creators.first,
                                    if (b.collection != null) b.collection!,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  tooltip: context.l10n.more,
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showActions(b, all),
                                ),
                                onTap: () => openArtwork(context, b.artwork),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
