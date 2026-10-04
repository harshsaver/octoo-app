import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/app_message.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/todo.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

enum ComposerMode { askOcto, tellHer }

/// The composer's state, shared with the thread (Reply and "Octo, do it"
/// set it).
class ComposerController extends ChangeNotifier {
  final text = TextEditingController();
  final focus = FocusNode();
  ComposerMode mode = ComposerMode.askOcto;

  /// The curated job chosen from the tray, while its prefill is in the field.
  String? job;

  /// The to-do being answered (sends `todo.reply`).
  Todo? replyTo;

  void setMode(ComposerMode value) {
    mode = value;
    if (value == ComposerMode.askOcto) replyTo = null;
    notifyListeners();
  }

  void replyToTodo(Todo todo) {
    replyTo = todo;
    mode = ComposerMode.tellHer;
    job = null;
    focus.requestFocus();
    notifyListeners();
  }

  void prefill(String value, {String? job}) {
    mode = ComposerMode.askOcto;
    replyTo = null;
    this.job = job;
    text
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    focus.requestFocus();
    notifyListeners();
  }

  void clear() {
    text.clear();
    job = null;
    replyTo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }
}

/// A quick job in the + tray (brief §5.4).
class TrayJob {
  const TrayJob(this.id, this.icon, this.label, {this.sendText, this.prefill});

  final String id;
  final IconData icon;
  final String Function(AppLocalizations) label;

  /// Sent straight away with this text.
  final String Function(AppLocalizations)? sendText;

  /// Put into the field to finish typing.
  final String Function(AppLocalizations)? prefill;

  bool get isScreenRequest => id == 'screen.request';
}

final trayJobs = <TrayJob>[
  TrayJob(
    'wifi.check',
    Icons.wifi,
    (l) => l.jobWifi,
    sendText: (l) => l.jobWifiText,
  ),
  TrayJob(
    'call.join',
    Icons.call_outlined,
    (l) => l.jobCall,
    prefill: (l) => l.jobCallPrefill,
  ),
  TrayJob(
    'find.show',
    Icons.search,
    (l) => l.jobFind,
    prefill: (l) => l.jobFindPrefill,
  ),
  TrayJob(
    'make.bigger',
    Icons.text_increase,
    (l) => l.jobBigger,
    prefill: (l) => l.jobBiggerPrefill,
  ),
  TrayJob(
    'app.install',
    Icons.download_outlined,
    (l) => l.jobInstall,
    prefill: (l) => l.jobInstallPrefill,
  ),
  TrayJob(
    'screen.describe',
    Icons.visibility_outlined,
    (l) => l.jobScreenDescribe,
    sendText: (l) => l.jobScreenDescribeText,
  ),
  const TrayJob(
    'screen.request',
    Icons.screenshot_monitor_outlined,
    _seeScreen,
  ),
];

String _seeScreen(AppLocalizations l) => l.jobSeeScreen;

class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.person,
    required this.online,
    required this.removed,
    required this.jobs,
    required this.onAsk,
    required this.onTell,
    required this.onReply,
    required this.onSeeScreen,
  });

  final ComposerController controller;
  final String person;
  final bool online;
  final bool removed;

  /// `status.jobs`, for the one-line "Octo will ask Mom before…" hint.
  final List<Job> jobs;
  final void Function(String text, String? job) onAsk;
  final void Function(String text) onTell;
  final void Function(Todo todo, String text) onReply;
  final VoidCallback onSeeScreen;

  void _send() {
    final text = controller.text.text.trim();
    if (text.isEmpty || text.length > maxMessageTextLength) return;
    final replyTo = controller.replyTo;
    if (replyTo != null) {
      onReply(replyTo, text);
    } else if (controller.mode == ComposerMode.tellHer) {
      onTell(text);
    } else {
      onAsk(text, controller.job);
    }
    controller.clear();
  }

  Future<void> _openTray(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<TrayJob>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.lg,
            0,
            OctoSpace.lg,
            OctoSpace.lg,
          ),
          child: Wrap(
            spacing: OctoSpace.sm,
            runSpacing: OctoSpace.sm,
            children: [
              for (final j in trayJobs)
                ActionChip(
                  avatar: Icon(j.icon, size: 20),
                  label: Text(j.label(l)),
                  onPressed: () => Navigator.pop(sheet, j),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    if (picked.isScreenRequest) {
      onSeeScreen();
    } else if (picked.sendText != null) {
      onAsk(picked.sendText!(l), picked.id);
    } else {
      controller.prefill(picked.prefill!(l), job: picked.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.text]),
      builder: (context, _) {
        final telling = controller.mode == ComposerMode.tellHer;
        final text = controller.text.text;
        final remaining = maxMessageTextLength - text.length;
        final canSend = !removed && text.trim().isNotEmpty && remaining >= 0;
        final job = controller.job == null
            ? null
            : jobs.where((j) => j.id == controller.job).firstOrNull;
        final hint = !telling && job != null && text.trim().isNotEmpty
            ? mayHint(l, job.mayKinds, person)
            : null;
        final reduceMotion =
            MediaQuery.maybeDisableAnimationsOf(context) ?? false;

        Widget line(String value, {Color? color}) => Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.lg,
            0,
            OctoSpace.lg,
            OctoSpace.xs,
          ),
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? colors.secondaryLabel,
            ),
          ),
        );

        return Material(
          color: colors.background,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                top: OctoSpace.xs,
                bottom: OctoSpace.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (removed)
                    line(l.composerRemoved(person), color: colors.needsYou)
                  else if (!online)
                    line(l.composerOffline(person)),
                  AnimatedSize(
                    duration: reduceMotion ? Duration.zero : OctoMotion.short,
                    child: hint == null
                        ? const SizedBox(width: double.infinity)
                        : line(hint),
                  ),
                  if (controller.replyTo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OctoSpace.md,
                      ),
                      child: InputChip(
                        label: Text(
                          l.replyingTo(controller.replyTo!.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          controller.replyTo = null;
                          controller.setMode(ComposerMode.askOcto);
                        },
                        deleteButtonTooltipMessage: l.cancel,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OctoSpace.md,
                      vertical: 2,
                    ),
                    child: SegmentedButton<ComposerMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: telling
                            ? colors.tellBubble
                            : colors.myBubble,
                        selectedForegroundColor: Colors.white,
                      ),
                      segments: [
                        ButtonSegment(
                          value: ComposerMode.askOcto,
                          label: Text(l.toggleAskOcto),
                        ),
                        ButtonSegment(
                          value: ComposerMode.tellHer,
                          label: Text(l.toggleTell(person)),
                        ),
                      ],
                      selected: {controller.mode},
                      onSelectionChanged: removed
                          ? null
                          : (s) => controller.setMode(s.single),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: l.quickJobs,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: colors.accent,
                          size: 30,
                        ),
                        onPressed: removed ? null : () => _openTray(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.text,
                          focusNode: controller.focus,
                          enabled: !removed,
                          minLines: 1,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: telling
                                ? l.tellPlaceholder(person)
                                : l.askOctoPlaceholder,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: colors.separator),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: colors.separator),
                            ),
                            counterText: '',
                            suffixText: remaining < 200
                                ? l.charactersLeft(remaining)
                                : null,
                            suffixStyle: TextStyle(
                              color: remaining < 0
                                  ? colors.needsYou
                                  : colors.secondaryLabel,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.send,
                        onPressed: canSend ? _send : null,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: telling
                              ? colors.tellBubble
                              : colors.myBubble,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: colors.separator,
                        ),
                      ),
                      const SizedBox(width: OctoSpace.xs),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
