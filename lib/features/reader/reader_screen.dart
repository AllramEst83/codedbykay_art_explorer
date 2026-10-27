import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:codedbykay_art_explorer/features/artwork/artwork_providers.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_document.dart';
import 'package:codedbykay_art_explorer/features/reader/reader_settings_sheet.dart';
import 'package:codedbykay_art_explorer/features/settings/settings_controller.dart';
import 'package:codedbykay_art_explorer/l10n/l10n_ext.dart';
import 'package:codedbykay_art_explorer/sources/art_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef ReaderArgs = ({Artwork artwork, ArtworkDetail? detail});

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.args, super.key});

  final ReaderArgs args;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scroll = ScrollController();
  FlutterTts? _tts;
  bool _speaking = false;
  bool _chrome = true;
  bool _restored = false;
  double _progress = 0;

  String get _posKey => 'reader.pos.${widget.args.artwork.key}';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _safely(WakelockPlus.enable);
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Plugins may be unavailable (tests, unsupported device).
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.005) setState(() => _progress = p);
  }

  void _restorePosition() {
    if (_restored) return;
    _restored = true;
    final saved = ref.read(sharedPreferencesProvider).getDouble(_posKey);
    if (saved == null || saved <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(saved * _scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    if (_scroll.hasClients) {
      ref.read(sharedPreferencesProvider).setDouble(_posKey, _progress);
    }
    _scroll.dispose();
    _safely(() async {
      await _tts?.stop();
    });
    _safely(WakelockPlus.disable);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _toggleSpeech(ReaderDocument doc) async {
    if (_speaking) {
      await _safely(() async {
        await _tts?.stop();
      });
      if (mounted) setState(() => _speaking = false);
      return;
    }
    try {
      final tts = _tts ??= FlutterTts();
      tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      await tts.setSpeechRate(0.45);
      setState(() => _speaking = true);
      await tts.speak(doc.spokenText);
    } on Object {
      if (!mounted) return;
      setState(() => _speaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.readAloudUnavailable)),
      );
    }
  }

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    SystemChrome.setEnabledSystemUIMode(
      _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.args.artwork;
    final prefs = ref.watch(readerPrefsProvider);

    final detailAsync = widget.args.detail != null
        ? null
        : ref.watch(
            artworkDetailProvider((source: artwork.sourceId, id: artwork.id)),
          );
    final detail = widget.args.detail ?? detailAsync?.value?.valueOrNull;
    final creatorName = artwork.creators.firstOrNull;
    final creator = creatorName == null
        ? null
        : ref.watch(creatorProvider(creatorName)).value?.valueOrNull;

    final doc = ReaderDocument.build(
      artwork: artwork,
      detail: detail,
      creator: creator,
      l10n: context.l10n,
      lang: Localizations.localeOf(context).languageCode,
    );
    final loadingMore =
        (detailAsync?.isLoading ?? false) ||
        (creatorName != null &&
            ref.watch(creatorProvider(creatorName)).isLoading);
    _restorePosition();

    final fg = prefs.theme.foreground;
    final base = prefs.font.style().copyWith(
      color: fg,
      fontSize: prefs.fontSize,
      height: prefs.lineHeight,
    );
    final isDark = prefs.theme == ReaderTheme.night;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: prefs.theme.background,
        appBar: _chrome
            ? AppBar(
                backgroundColor: prefs.theme.background,
                foregroundColor: fg,
                surfaceTintColor: Colors.transparent,
                title: Text(context.l10n.reader),
                actions: [
                  IconButton(
                    tooltip: _speaking
                        ? context.l10n.stopReading
                        : context.l10n.readAloud,
                    icon: Icon(
                      _speaking ? Icons.stop_circle_outlined : Icons.volume_up,
                    ),
                    onPressed: doc.hasContent ? () => _toggleSpeech(doc) : null,
                  ),
                  IconButton(
                    tooltip: context.l10n.readingSettings,
                    icon: const Icon(Icons.text_fields),
                    onPressed: () => showReaderSettings(context),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: fg.withValues(alpha: 0.1),
                    color: fg.withValues(alpha: 0.6),
                  ),
                ),
              )
            : null,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleChrome,
          child: SelectionArea(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(prefs.margin, 16, prefs.margin, 48),
              children: [
                Text(
                  doc.title,
                  style: base.copyWith(
                    fontSize: prefs.fontSize * 1.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 24),
                for (final s in doc.sections)
                  if (s.paragraphs.any((p) => p.isNotEmpty)) ...[
                    Text(
                      s.heading,
                      style: base.copyWith(
                        fontSize: prefs.fontSize * 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final p in s.paragraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(p, style: base),
                      ),
                    if (s.attribution != null)
                      Text(
                        s.attribution!,
                        style: base.copyWith(
                          fontSize: prefs.fontSize * 0.7,
                          fontStyle: FontStyle.italic,
                          color: fg.withValues(alpha: 0.65),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                if (loadingMore)
                  const Center(child: CircularProgressIndicator())
                else if (!doc.hasContent)
                  Text(context.l10n.noDescription, style: base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
