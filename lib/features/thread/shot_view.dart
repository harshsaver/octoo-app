import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../data/screenshot_store.dart';
import '../../data/session/session_data.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// A screenshot in the thread. Only files in the app-private store are
/// ever shown; a path on her computer is never opened.
class ShotView extends ConsumerWidget {
  const ShotView({
    super.key,
    required this.shot,
    required this.semanticLabel,
    this.caption,
  });

  final ShotRef shot;
  final String semanticLabel;
  final String? caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    ref.watch(screenshotChangesProvider);
    final store = ref.watch(screenshotStoreProvider);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.66;

    Widget placeholder(String text, {bool busy = false}) => Container(
      width: maxWidth,
      height: maxWidth * 0.62,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(OctoSpace.lg),
      decoration: BoxDecoration(
        color: colors.otherBubble,
        borderRadius: BorderRadius.circular(OctoSpace.bubbleRadius),
      ),
      child: busy
          ? const CircularProgressIndicator.adaptive()
          : Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryLabel),
            ),
    );

    switch (shot) {
      case HostShot():
        return placeholder(l.screenshotOnHerComputer);
      case UnavailableShot():
        return placeholder(l.screenshotUnavailable);
      case LocalShot(:final id):
        switch (store.status(id)) {
          case ShotStatus.writing:
            return placeholder('', busy: true);
          case ShotStatus.missing:
            return placeholder(l.screenshotUnavailable);
          case ShotStatus.ready:
            final file = store.fileFor(id);
            if (file == null) return placeholder(l.screenshotUnavailable);
            final dpr = MediaQuery.devicePixelRatioOf(context);
            return Semantics(
              image: true,
              button: true,
              label: semanticLabel,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) =>
                        ImageViewer(shotId: id, label: semanticLabel),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(OctoSpace.bubbleRadius),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxWidth * 1.4,
                    ),
                    child: Image(
                      image: ResizeImage(
                        FileImage(file),
                        width: (maxWidth * dpr).round(),
                      ),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) =>
                          placeholder(l.screenshotUnavailable),
                    ),
                  ),
                ),
              ),
            );
        }
    }
  }
}

/// Full-screen viewer with pinch-to-zoom and the system share sheet.
class ImageViewer extends ConsumerWidget {
  const ImageViewer({super.key, required this.shotId, required this.label});

  final String shotId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(screenshotChangesProvider);
    final store = ref.watch(screenshotStoreProvider);
    final file = store.fileFor(shotId);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (file != null)
            IconButton(
              tooltip: l.share,
              icon: const Icon(Icons.ios_share),
              onPressed: () async {
                final copy = await store.shareCopy(shotId);
                if (copy == null) return;
                await SharePlus.instance.share(
                  ShareParams(files: [XFile(copy.path)]),
                );
              },
            ),
        ],
      ),
      body: file == null
          ? Center(
              child: Text(
                l.screenshotUnavailable,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Semantics(
                  image: true,
                  label: label,
                  child: Image.file(file, excludeFromSemantics: true),
                ),
              ),
            ),
    );
  }
}
