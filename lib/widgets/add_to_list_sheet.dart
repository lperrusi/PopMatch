import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/watchlist_list.dart';
import '../services/watchlist_service.dart';
import '../utils/l10n_extension.dart';
import '../utils/theme.dart';

/// Opens the "Add to list / tag" sheet for a movie. All local (WatchlistService);
/// no backend required.
Future<void> showAddToListSheet(
  BuildContext context, {
  required String movieId,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddToListSheet(movieId: movieId, title: title),
  );
}

/// Lets the user add a title to custom lists and tag it. Reads/writes the local
/// [WatchlistService] (SharedPreferences) — works offline.
class AddToListSheet extends StatefulWidget {
  final String movieId;
  final String title;

  const AddToListSheet({super.key, required this.movieId, required this.title});

  @override
  State<AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<AddToListSheet> {
  final WatchlistService _service = WatchlistService.instance;
  final TextEditingController _newListController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  List<WatchlistList> _lists = [];
  Set<String> _containingListIds = {};
  List<String> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lists = await _service.getLists();
    final containing = await _service.getListsContainingMovie(widget.movieId);
    final tagMap = await _service.getMovieTags();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _containingListIds = containing.map((l) => l.id).toSet();
      _tags = List<String>.from(tagMap[widget.movieId] ?? const []);
      _loading = false;
    });
  }

  Future<void> _toggleList(WatchlistList list) async {
    final inList = _containingListIds.contains(list.id);
    setState(() {
      if (inList) {
        _containingListIds.remove(list.id);
      } else {
        _containingListIds.add(list.id);
      }
    });
    if (inList) {
      await _service.removeMovieFromList(list.id, widget.movieId);
    } else {
      await _service.addMovieToList(list.id, widget.movieId);
    }
  }

  Future<void> _createAndAdd() async {
    final name = _newListController.text.trim();
    if (name.isEmpty) return;
    final list = await _service.createList(name: name);
    if (!mounted) return;
    if (list == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.listNameExists),
          backgroundColor: AppTheme.cinemaRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _service.addMovieToList(list.id, widget.movieId);
    _newListController.clear();
    await _load();
  }

  Future<void> _addTag() async {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    await _service.addTagToMovie(widget.movieId, tag);
    if (!mounted) return;
    setState(() => _tags = [..._tags, tag]);
    _tagController.clear();
  }

  Future<void> _removeTag(String tag) async {
    await _service.removeTagFromMovie(widget.movieId, tag);
    if (!mounted) return;
    setState(() => _tags = _tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vintagePaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.addToListTitle,
                style: GoogleFonts.bebasNeue(
                  fontSize: 26,
                  color: AppTheme.cinemaRed,
                  letterSpacing: 1,
                ),
              ),
              Text(
                widget.title,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.cinemaRed),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.noListsYet,
                              style: GoogleFonts.lato(
                                color:
                                    AppTheme.filmStripBlack.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        else
                          ..._lists.map((list) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: AppTheme.cinemaRed,
                                value: _containingListIds.contains(list.id),
                                onChanged: (_) => _toggleList(list),
                                title: Text(
                                  list.name,
                                  style: GoogleFonts.lato(
                                    color: AppTheme.filmStripBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newListController,
                                decoration: InputDecoration(
                                  hintText: l10n.newListHint,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _createAndAdd(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _createAndAdd,
                              child: Text(l10n.createButton),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tagsLabel,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            color: AppTheme.filmStripBlack,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _tags
                                .map((t) => Chip(
                                      label: Text(t),
                                      onDeleted: () => _removeTag(t),
                                      backgroundColor: AppTheme.popcornGold
                                          .withValues(alpha: 0.25),
                                    ))
                                .toList(),
                          ),
                        TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: l10n.addTagHint,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
