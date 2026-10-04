import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/providers.dart';
import '../../data/backend/octo_backend.dart';
import '../../data/computer_settings.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../transport/simulator/debug_panel.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/octo_looks.dart';
import '../../ui/theme.dart';
import '../../ui/time_format.dart';
import '../../ui/tokens.dart';
import 'list_model.dart';

/// The Octos list: Messages' conversation list (brief §5.2).
class OctosListScreen extends ConsumerStatefulWidget {
  const OctosListScreen({super.key});

  @override
  ConsumerState<OctosListScreen> createState() => _OctosListScreenState();
}

class _OctosListScreenState extends ConsumerState<OctosListScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  bool _editing = false;
  Timer? _tick;
  StreamSubscription<String>? _banners;

  @override
  void initState() {
    super.initState();
    // Relative times ("2 min ago") stay current.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _banners = ref.read(sessionsControllerProvider).banners.listen((person) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).removedBanner(person)),
        ),
      );
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _banners?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final computers = ref.watch(computersProvider);
    final isFake = ref.watch(appConfigProvider).isFake;
    final now = clock.now();

    final rows = computers.value == null
        ? null
        : orderRows([
            for (final c in computers.value!)
              buildRowModel(
                computer: c,
                data: ref.watch(sessionDataProvider(c.id)).value,
                thread: ref.watch(threadProvider(c.id)),
                l: l,
                now: now,
              ),
          ]);
    final visible = rows?.where((r) => matchesSearch(r, _search.text)).toList();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Pull down to reveal search, as in Messages.
          if (!_searching &&
              n is OverscrollNotification &&
              n.overscroll < -8 &&
              (rows?.isNotEmpty ?? false)) {
            setState(() => _searching = true);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar.large(
              title: Text(l.octosTitle),
              centerTitle: false,
              leadingWidth: 148,
              // Settings from a small avatar at the top left, then Edit.
              leading: Row(
                children: [
                  const SizedBox(width: OctoSpace.xs),
                  IconButton(
                    tooltip: l.settings,
                    onPressed: () => context.push('/settings'),
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: colors.accentText,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text(
                        ref.watch(accountProvider).name.characters.first,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  if (!(rows?.isEmpty ?? true))
                    TextButton(
                      onPressed: () => setState(() => _editing = !_editing),
                      child: Text(_editing ? l.done : l.edit),
                    ),
                ],
              ),
              actions: [
                if (isFake && ref.watch(appSettingsProvider).showSimulator)
                  IconButton(
                    tooltip: l.playMom,
                    icon: const Icon(Icons.bug_report_outlined),
                    onPressed: () => DebugPanel.show(
                      context,
                      ref.read(simulatorLinkProvider),
                    ),
                  ),
                IconButton(
                  tooltip: l.addOcto,
                  iconSize: 32,
                  icon: const Icon(Icons.add_circle),
                  color: colors.accent,
                  onPressed: () => context.push('/add'),
                ),
                const SizedBox(width: OctoSpace.sm),
              ],
            ),
            if (_searching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OctoSpace.lg,
                    0,
                    OctoSpace.lg,
                    OctoSpace.sm,
                  ),
                  child: SearchBar(
                    controller: _search,
                    hintText: l.search,
                    elevation: const WidgetStatePropertyAll(0),
                    leading: const Icon(Icons.search),
                    trailing: [
                      IconButton(
                        tooltip: l.cancel,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _search.clear();
                          _searching = false;
                        }),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            if (rows == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (rows.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: () => context.push('/add')),
              )
            else if (visible!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l.noMatches(_search.text),
                    style: TextStyle(color: colors.secondaryLabel),
                  ),
                ),
              )
            else if (_editing)
              SliverReorderableList(
                itemCount: visible.length,
                onReorderItem: (from, to) => _reorder(visible, from, to),
                itemBuilder: (context, i) => _EditRow(
                  key: ValueKey(visible[i].computer.id),
                  index: i,
                  row: visible[i],
                  onTogglePin: () => _setPinned(
                    visible[i].computer,
                    !visible[i].computer.pinned,
                  ),
                  onRemove: () => _confirmRemove(visible[i].computer),
                ),
              )
            else
              SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) => _SlidableRow(
                  key: ValueKey(visible[i].computer.id),
                  row: visible[i],
                  now: now,
                  onOpen: () => _open(visible[i].computer),
                  onToggleMute: () => _setMuted(
                    visible[i].computer,
                    !visible[i].computer.muted,
                  ),
                  onRemove: () => _confirmRemove(visible[i].computer),
                  onToggleRead: () => _toggleRead(visible[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  OctoDatabase get _db => ref.read(databaseProvider);

  Future<void> _open(ComputerRow c) async {
    await ref.read(sessionsControllerProvider).markRead(c.id);
    if (mounted) await context.push('/octo/${c.id}');
  }

  Future<void> _setMuted(ComputerRow c, bool muted) async {
    try {
      await setComputerMuted(_db, ref.read(backendProvider), c.id, muted);
    } on BackendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _setPinned(ComputerRow c, bool pinned) =>
      _db.updateComputer(c.id, ComputersCompanion(pinned: Value(pinned)));

  Future<void> _toggleRead(OctoRowModel row) {
    final at = row.unread
        ? clock.now().millisecondsSinceEpoch
        : ((row.latestIncomingAt ?? row.latestAt ?? 1) - 1);
    return _db.updateComputer(
      row.computer.id,
      ComputersCompanion(lastReadAt: Value(at)),
    );
  }

  Future<void> _reorder(List<OctoRowModel> rows, int from, int to) async {
    final ids = [for (final r in rows) r.computer.id];
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    for (var i = 0; i < ids.length; i++) {
      await _db.updateComputer(ids[i], ComputersCompanion(sortOrder: Value(i)));
    }
  }

  Future<void> _confirmRemove(ComputerRow c) async {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.xl,
            0,
            OctoSpace.xl,
            OctoSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.removeTitle(c.person),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: OctoSpace.sm),
              Text(
                c.role == 'owner'
                    ? l.removeBodyOwner(c.computerName)
                    : l.removeBodyHelper(c.computerName),
              ),
              const SizedBox(height: OctoSpace.xl),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.needsYou,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.remove),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(sessionsControllerProvider).remove(c.id);
    } on BackendException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.removeFailed(e.message))));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OctoSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: OctoSpace.xxl),
          const OctoAvatar(size: 140),
          const SizedBox(height: OctoSpace.xl),
          Text(
            l.emptyTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: OctoSpace.xl),
          IconButton.filled(
            tooltip: l.addOcto,
            iconSize: 40,
            style: IconButton.styleFrom(
              backgroundColor: colors.accentText,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(72, 72),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: OctoSpace.xl),
          Text(
            l.emptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _SlidableRow extends StatelessWidget {
  const _SlidableRow({
    super.key,
    required this.row,
    required this.now,
    required this.onOpen,
    required this.onToggleMute,
    required this.onRemove,
    required this.onToggleRead,
  });

  final OctoRowModel row;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onToggleMute;
  final VoidCallback onRemove;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    return Slidable(
      groupTag: 'octos',
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onToggleRead(),
            backgroundColor: colors.tellBubble,
            foregroundColor: Colors.white,
            icon: row.unread
                ? Icons.mark_chat_read_outlined
                : Icons.mark_chat_unread_outlined,
            label: row.unread ? l.markRead : l.markUnread,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onToggleMute(),
            backgroundColor: const Color(0xFF5856D6),
            foregroundColor: Colors.white,
            icon: row.computer.muted
                ? Icons.notifications_outlined
                : Icons.notifications_off_outlined,
            label: row.computer.muted ? l.unmute : l.mute,
          ),
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: colors.needsYou,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: l.remove,
          ),
        ],
      ),
      child: _RowTile(row: row, now: now, onTap: onOpen),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.now, required this.onTap});

  final OctoRowModel row;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    final c = row.computer;
    final previewColor = switch (row.kind) {
      PreviewKind.working => colors.working,
      PreviewKind.needsHand => colors.needsYou,
      _ => colors.secondaryLabel,
    };
    final time = row.latestAt == null ? '' : listTime(l, row.latestAt!, now);
    final dotColor = row.needsHand
        ? colors.needsYou
        : (row.unread ? colors.accent : null);
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: [
          c.person,
          row.preview,
          time,
          if (row.unread) l.unread,
          if (c.muted) l.muted,
          if (c.pinned) l.pinned,
        ].where((s) => s.isNotEmpty).join('. '),
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                OctoSpace.sm,
                OctoSpace.sm,
                OctoSpace.lg,
                OctoSpace.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: dotColor == null
                        ? null
                        : Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: OctoSpace.xs),
                  OctoAvatar(
                    look: OctoLook.fromId(c.look),
                    size: 52,
                    mood: row.mood,
                    celebrateKey: row.celebrateKey,
                  ),
                  const SizedBox(width: OctoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.person,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (c.muted)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: OctoSpace.xs,
                                ),
                                child: Icon(
                                  Icons.notifications_off,
                                  size: 14,
                                  color: colors.secondaryLabel,
                                ),
                              ),
                            Text(
                              time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: previewColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    super.key,
    required this.index,
    required this.row,
    required this.onTogglePin,
    required this.onRemove,
  });

  final int index;
  final OctoRowModel row;
  final VoidCallback onTogglePin;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    return Material(
      color: colors.background,
      child: Row(
        children: [
          IconButton(
            tooltip: l.remove,
            icon: Icon(Icons.remove_circle, color: colors.needsYou),
            onPressed: onRemove,
          ),
          Expanded(
            child: _RowTile(row: row, now: clock.now(), onTap: null),
          ),
          IconButton(
            tooltip: row.computer.pinned ? l.unpin : l.pin,
            icon: Icon(
              row.computer.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              onTogglePin();
            },
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(OctoSpace.md),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}
