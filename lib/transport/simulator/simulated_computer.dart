import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';

import '../../protocol/app_message.dart';
import '../../protocol/host_message.dart';
import '../../protocol/models/entry.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/screenshot.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import 'sample_screen.dart';
import 'sim_jobs.dart';

/// How the next pairing behaves, for trying the outcome screens.
enum SimPairingScript {
  /// The codes match and she is asked to tap OK.
  normal,

  /// Her computer rejects the confirmed code ("That code doesn't match").
  /// The third wrong try is final ("Too many wrong tries").
  wrongCode,

  /// The code expires a few seconds after it's shown.
  codeExpires,
}

/// Knobs shared by every simulated computer. Changing them takes effect for
/// the next thing that happens.
class SimulatorSettings {
  SimulatorSettings({
    this.autopilot = true,
    this.momDelay = const Duration(milliseconds: 2500),
    this.stepInterval = const Duration(milliseconds: 1600),
    this.consentTimeout = const Duration(minutes: 2),
    this.pairingScript = SimPairingScript.normal,
    this.helperName = 'Harsh',
  });

  /// Mom answers OK by herself after [momDelay].
  bool autopilot;
  Duration momDelay;
  Duration stepInterval;

  /// How long she has to answer before a task ends as `noAnswer`.
  Duration consentTimeout;
  SimPairingScript pairingScript;

  /// The helper name used when the simulator has to recreate a computer it
  /// doesn't know (for example after the app restarts).
  String helperName;
}

enum ConsentKind { pairing, task, screen, policy }

/// Something waiting for Mom to tap OK or No on her computer.
class PendingConsent {
  PendingConsent._(this.kind, this.prompt, this._onAnswer, this.taskId);

  final ConsentKind kind;

  /// The task she's asked about, for [ConsentKind.task].
  final String? taskId;

  /// What her screen says, e.g. "Harsh asked me to join a call. OK?".
  final String prompt;
  final void Function(bool? ok) _onAnswer;
  Timer? _auto;
  Timer? _expiry;
}

class SimHelper {
  const SimHelper({required this.id, required this.name, required this.device});

  final String id;
  final String name;
  final String device;
}

/// Mom's computer, played in-app: Octo's engine as far as this app can see
/// it. Speaks the brief's §7.2 protocol as JSON maps through [receive] and
/// [outbound]. All timing uses [Timer] and `clock`, so tests drive it with
/// `fake_async`.
class SimulatedComputer {
  SimulatedComputer({
    required this.computerId,
    required this.hostId,
    required this.computerName,
    this.person = 'Mom',
    this.language = 'en',
    this.os = 'windows',
    SimulatorSettings? settings,
    Random? random,
  }) : settings = settings ?? SimulatorSettings(),
       _random = random ?? Random();

  final String computerId;
  final String hostId;
  final String os;
  String computerName;
  String person;
  String language;
  final SimulatorSettings settings;
  final Random _random;

  Policy policy = const Policy();
  final Map<String, SimHelper> helpers = {};
  final Map<String, Task> tasks = {};
  final Map<String, Todo> todos = {};
  final List<Entry> log = [];
  HelpState? help;

  /// Lines her screen showed, oldest first (the debug panel shows them).
  final List<String> momScreen = [];

  final List<PendingConsent> _consents = [];
  List<PendingConsent> get consents => List.unmodifiable(_consents);

  final List<String> _queue = [];
  String? _activeId;
  final Map<String, Timer> _taskTimers = {};
  _Pairing? _pairing;
  int _wrongCodeTries = 0;
  int _todoSample = 0;
  bool _disposed = false;

  final _outbound = StreamController<Map<String, Object?>>.broadcast(
    sync: true,
  );
  final _changes = StreamController<void>.broadcast(sync: true);
  final _online = StreamController<bool>.broadcast(sync: true);

  /// Messages to the app, in order.
  Stream<Map<String, Object?>> get outbound => _outbound.stream;

  /// Fires whenever anything the debug panel shows changes.
  Stream<void> get changes => _changes.stream;

  /// Fires when the computer goes offline (false) or comes back (true).
  Stream<bool> get onlineChanges => _online.stream;

  bool _isOnline = true;
  bool get online => _isOnline;

  bool get isPairing => _pairing != null;

  Task? get activeTask => _activeId == null ? null : tasks[_activeId];

  // ---------------------------------------------------------------------
  // App → her computer

  /// Handles one message from the helper [from].
  void receive(Map<String, Object?> raw, {required String from}) {
    if (_disposed) return;
    final message = AppMessage.parse(raw);
    final helper = helpers[from];
    switch (message) {
      case PairRequest():
        _pairRequest(message, from);
      case PairConfirm():
        _pairConfirm(message, from);
      case _ when helper == null:
        // Not paired: her computer ignores everything else.
        break;
      case StatusRequest(:final requestId):
        _emit(StatusMessage(requestId: requestId, status: status()));
      case TaskCreate():
        _taskCreate(message, helper);
      case TaskStop():
        _taskStop(message, helper);
      case PolicySet():
        _policySet(message, helper);
      case ProfileSet():
        computerName = message.computer ?? computerName;
        person = message.person ?? person;
        language = message.language ?? language;
        _result(message.requestId, ok: true);
        _notify();
      case TodosRequest(:final requestId):
        _emit(TodosMessage(requestId: requestId, todos: todos.values.toList()));
      case TodoReply():
        _todoReply(message, helper);
      case TodoDone(:final todoId):
        final todo = todos[todoId];
        if (todo != null) _emitTodo(todo.copyWith(done: true));
      case LogRequest():
        _logRequest(message);
      case ChatMessage(:final text):
        _clearHelp();
        _addLog('message', helper.name, text);
        _show('${helper.name}: $text');
      case ScreenRequest():
        _screenRequest(helper);
      case Leave():
        helpers.remove(from);
        _addLog('pairing', helper.name, '${helper.device} was removed');
        _notify();
      case UnknownAppMessage():
        break;
    }
  }

  // ---------------------------------------------------------------------
  // Mom's side (the debug panel)

  void momSaysOk({ConsentKind? kind}) => _answerFirst(kind, true);

  void momSaysNo({ConsentKind? kind}) => _answerFirst(kind, false);

  /// Mom sends a to-do ("Send to Harsh") with a screenshot and Octo's answer.
  void sendTodo() {
    const samples = [
      (
        text: 'Is this email real?',
        answer: "It looks like a scam: the sender isn't your bank. Don't click the link.",
        app: 'Microsoft Edge',
        window: 'Inbox – Outlook',
        url: 'https://outlook.live.com/mail',
      ),
      (
        text: 'Is this safe?',
        answer: 'This pop-up is an ad pretending to be a warning. You can close it.',
        app: 'Google Chrome',
        window: 'Your computer has a virus!',
        url: 'https://example.com/alert',
      ),
      (
        text: 'Can you fix the printer?',
        answer: 'The printer looks offline. Check that it is turned on.',
        app: 'Settings',
        window: 'Printers & scanners',
        url: null,
      ),
    ];
    final s = samples[_todoSample++ % samples.length];
    final todo = Todo(
      id: 'd_${_hex(10)}',
      at: _now(),
      text: s.text,
      answer: s.answer,
      screenshot: WireScreenshot.fromWire(sampleScreenDataUri),
      context: TodoContext(app: s.app, window: s.window, url: s.url),
    );
    _addLog('todo', person, s.text);
    _show('$person sent: ${s.text}');
    _emitTodo(todo);
  }

  /// Mom taps "Ask for help".
  void askForHelp([String text = "The printer isn't working"]) {
    final at = _now();
    help = HelpState(since: at, text: text);
    _addLog('help', person, text);
    _show('$person asked for help: $text');
    _emit(HelpMessage(at: at, text: text));
  }

  void goOffline() => _setOnline(false);

  void goOnline() => _setOnline(true);

  /// Mom removes the helper [helperId] from her computer.
  void removeHelper(String helperId) {
    final helper = helpers.remove(helperId);
    if (helper == null) return;
    _addLog('pairing', person, '${helper.device} was removed');
    _emit(const RemovedMessage());
  }

  /// Another helper (Priya) sends a task, so the thread shows someone else's.
  void otherHelperAsks([String text = 'Install Zoom']) {
    const priya = SimHelper(
      id: 'u_priya',
      name: 'Priya',
      device: "Priya's Pixel",
    );
    helpers.putIfAbsent(priya.id, () => priya);
    _createTask(priya, text, null);
  }

  /// Abandons a pairing in progress (the app cancelled it).
  void cancelPairing() {
    final pairing = _pairing;
    if (pairing == null) return;
    pairing.expiry.cancel();
    _consents
        .where((c) => c.kind == ConsentKind.pairing)
        .toList()
        .forEach(_drop);
    _pairing = null;
    _notify();
  }

  /// The body of a `status` reply.
  ComputerStatus status() {
    final active = activeTask;
    final ended = tasks.values.where((t) => t.phase.isEnded).toList()
      ..sort((a, b) => (b.endedAt ?? 0).compareTo(a.endedAt ?? 0));
    return ComputerStatus(
      computer: computerName,
      person: person,
      language: language,
      os: os,
      busy: active?.phase == TaskPhase.running,
      task: active,
      queued: [for (final id in _queue) tasks[id]!],
      recent: ended.take(20).toList(),
      todos: TodoCounts(open: todos.values.where((t) => !t.done).length),
      help: help,
      policy: policy,
      family: [
        for (final h in helpers.values)
          FamilyMember(name: h.name, device: h.device),
      ],
      jobs: [for (final j in simJobs) j.job],
      agent: const AgentState(connected: true),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final t in _taskTimers.values) {
      t.cancel();
    }
    for (final c in _consents) {
      c._auto?.cancel();
      c._expiry?.cancel();
    }
    _pairing?.expiry.cancel();
    _outbound.close();
    _changes.close();
    _online.close();
  }

  // ---------------------------------------------------------------------
  // Pairing

  void _pairRequest(PairRequest m, String from) {
    if (_pairing != null && _pairing!.helperId != from) {
      _emit(
        const PairFailedMessage(
          reason: 'Someone else is adding a family member right now. Try again in a minute.',
          isFinal: false,
        ),
      );
      return;
    }
    final code = (_random.nextInt(900000) + 100000).toString();
    final expiresIn = settings.pairingScript == SimPairingScript.codeExpires
        ? const Duration(seconds: 5)
        : const Duration(minutes: 5);
    _pairing = _Pairing(
      helperId: from,
      name: m.name,
      device: m.device,
      code: code,
      expiry: Timer(expiresIn, () {
        cancelPairing();
        _emit(
          const PairFailedMessage(
            reason: 'The code expired. Start again on her computer.',
            isFinal: true,
          ),
        );
      }),
    );
    _show(
      'Octo: ${m.name} wants to help with this computer. '
      'Key ${code.substring(0, 3)} ${code.substring(3)}',
    );
    _emit(PairCodeMessage(code: code, computer: computerName));
  }

  void _pairConfirm(PairConfirm m, String from) {
    final pairing = _pairing;
    if (pairing == null || pairing.helperId != from) return;
    final wrong =
        settings.pairingScript == SimPairingScript.wrongCode ||
        m.code != pairing.code;
    if (wrong) {
      _wrongCodeTries++;
      final isFinal = _wrongCodeTries >= 3;
      cancelPairing();
      _emit(
        PairFailedMessage(
          reason: isFinal
              ? 'Too many wrong tries. Start again on her computer.'
              : "That code doesn't match.",
          isFinal: isFinal,
        ),
      );
      return;
    }
    _ask(
      ConsentKind.pairing,
      '${pairing.name} wants to help with this computer. OK?',
      (ok) {
        if (_pairing != pairing) return;
        pairing.expiry.cancel();
        _pairing = null;
        if (ok == true) {
          _wrongCodeTries = 0;
          helpers[pairing.helperId] = SimHelper(
            id: pairing.helperId,
            name: pairing.name,
            device: pairing.device,
          );
          _addLog('pairing', person, '${pairing.device} was added');
          _emit(
            PairDoneMessage(
              hostId: hostId,
              computer: computerName,
              person: person,
            ),
          );
        } else {
          _emit(PairFailedMessage(reason: '$person said no.', isFinal: true));
        }
        _notify();
      },
    );
  }

  // ---------------------------------------------------------------------
  // Tasks

  void _taskCreate(TaskCreate m, SimHelper helper) {
    final text = m.text.trim();
    if (text.isEmpty || m.text.length > maxMessageTextLength) {
      _result(
        m.requestId,
        ok: false,
        error: 'bad_request',
        message: 'Write what Octo should do, in up to 2,000 characters.',
      );
      return;
    }
    if (m.job != null && simJobById(m.job!) == null) {
      _result(
        m.requestId,
        ok: false,
        error: 'unknown_job',
        message: 'Octo doesn\'t know the job “${m.job}”.',
      );
      return;
    }
    final waiting = tasks.values
        .where(
          (t) => t.phase == TaskPhase.queued || t.phase == TaskPhase.waitingOk,
        )
        .length;
    if (waiting >= 10) {
      _result(
        m.requestId,
        ok: false,
        error: 'busy',
        message:
            'Octo already has 10 things waiting. Try again when one finishes.',
      );
      return;
    }
    final task = _createTask(helper, text, m.job);
    _result(m.requestId, ok: true, taskId: task.id);
  }

  Task _createTask(SimHelper helper, String text, String? jobId) {
    final sim = jobId == null ? guessSimJob(text) : simJobById(jobId)!;
    final task = Task(
      id: 't_${_hex(12)}',
      from: helper.id,
      fromName: helper.name,
      text: text,
      job: sim.job.id,
      scope: sim.job.scope,
      may: sim.job.may,
      status: 'queued',
      createdAt: _now(),
    );
    _clearHelp();
    _addLog('task', helper.name, text, taskId: task.id, job: sim.job.id);
    _queue.add(task.id);
    _emitTask(task);
    _pump();
    return task;
  }

  /// Starts the next queued task when nothing is active.
  void _pump() {
    if (_activeId != null || _queue.isEmpty) return;
    final id = _queue.removeAt(0);
    _activeId = id;
    final task = tasks[id]!;

    final refusal = _refusalFor(task);
    if (refusal != null) {
      _end(task, 'refused', refusal);
      return;
    }
    final scope = task.scopeKind;
    const risky = {
      ChangeKind.install,
      ChangeKind.delete,
      ChangeKind.send,
      ChangeKind.signIn,
      ChangeKind.call,
    };
    final needsOk = scope == TaskScope.look
        ? policy.askBeforeLooking
        : policy.askEveryChange || task.mayKinds.any(risky.contains);
    if (!needsOk) {
      _run(task);
      return;
    }
    final waiting = _emitTask(task.copyWith(status: 'waitingOk'));
    _ask(
      ConsentKind.task,
      '${task.fromName} asked me to ${_lowerFirst(task.text)}. OK?',
      (ok) {
        final current = tasks[waiting.id]!;
        if (current.phase != TaskPhase.waitingOk) return;
        if (ok == true) {
          _addLog(
            'consent',
            person,
            '$person said OK',
            taskId: current.id,
            outcome: 'ok',
          );
          _run(current);
        } else if (ok == false) {
          _addLog(
            'consent',
            person,
            '$person said no',
            taskId: current.id,
            outcome: 'no',
          );
          _end(current, 'declined', '$person said no.');
        } else {
          _end(current, 'noAnswer', "$person didn't answer.");
        }
      },
      expiresAfter: settings.consentTimeout,
      taskId: waiting.id,
    );
  }

  String? _refusalFor(Task task) {
    for (final kind in task.mayKinds) {
      if (policy.neverKinds.contains(kind)) {
        return "Your rules say Octo can't ${_changeVerb(kind)} on $person's computer.";
      }
    }
    final lower = task.text.toLowerCase();
    for (final site in policy.blockedSites) {
      if (site.isNotEmpty && lower.contains(site.toLowerCase())) {
        return 'Your rules keep Octo off $site.';
      }
    }
    return null;
  }

  void _run(Task task) {
    final sim = simJobById(task.job ?? '') ?? generalJob;
    final limit = hardLimitFor(task.text, person);
    var current = _emitTask(
      task.copyWith(
        status: 'running',
        startedAt: _now(),
        say: sim.steps.first.say,
      ),
    );
    var n = 0;
    void next() {
      final step = sim.steps[n];
      n++;
      current = tasks[current.id]!;
      final steps = [
        ...current.steps,
        TaskStep(n: n, at: _now(), say: step.say, did: step.did, ok: true),
      ];
      _addLog('step', 'Octo', step.did, taskId: current.id);
      if (limit != null) {
        _addLog('limit', 'Octo', limit.result, taskId: current.id);
        _end(
          current.copyWith(steps: steps),
          'blocked',
          limit.result,
          resultForHer: limit.forHer,
        );
        return;
      }
      if (n >= sim.steps.length) {
        _end(
          current.copyWith(steps: steps),
          'done',
          sim.result,
          resultForHer: sim.resultForHer,
          screenshot: WireScreenshot.fromWire(sampleScreenDataUri),
        );
        return;
      }
      current = _emitTask(
        current.copyWith(steps: steps, say: sim.steps[n].say),
      );
      _taskTimers[current.id] = Timer(settings.stepInterval, next);
    }

    _taskTimers[current.id] = Timer(settings.stepInterval, next);
  }

  void _end(
    Task task,
    String status,
    String result, {
    String? resultForHer,
    WireScreenshot? screenshot,
  }) {
    _taskTimers.remove(task.id)?.cancel();
    _queue.remove(task.id);
    final ended = _emitTask(
      task.copyWith(
        status: status,
        say: null,
        result: result,
        resultForHer: resultForHer,
        screenshot: screenshot,
        endedAt: _now(),
      ),
    );
    _addLog(
      'task',
      'Octo',
      result,
      taskId: ended.id,
      job: ended.job,
      outcome: status,
    );
    if (resultForHer != null) _show('Octo: $resultForHer');
    if (_activeId == task.id) {
      _activeId = null;
      _pump();
    }
  }

  void _taskStop(TaskStop m, SimHelper helper) {
    final task = tasks[m.taskId];
    if (task == null) {
      _result(
        m.requestId,
        ok: false,
        error: 'not_found',
        message: "Octo can't find that task.",
      );
      return;
    }
    if (!task.phase.isActive) {
      _result(
        m.requestId,
        ok: false,
        error: 'bad_request',
        message: 'That task already finished.',
      );
      return;
    }
    _consents.where((c) => c.taskId == task.id).toList().forEach(_drop);
    _result(m.requestId, ok: true);
    _end(task, 'stopped', 'Stopped by ${helper.name}.');
  }

  // ---------------------------------------------------------------------
  // Rules, screen, to-dos, log

  void _policySet(PolicySet m, SimHelper helper) {
    final active = policy;
    final proposed = m.policy;
    final tightened = active.copyWith(
      askEveryChange: active.askEveryChange || proposed.askEveryChange,
      askBeforeLooking: active.askBeforeLooking || proposed.askBeforeLooking,
      never: _union(active.never, proposed.never),
      blockedSites: _union(active.blockedSites, proposed.blockedSites),
    );
    final loosens =
        (active.askEveryChange && !proposed.askEveryChange) ||
        (active.askBeforeLooking && !proposed.askBeforeLooking) ||
        active.never.any((n) => !proposed.never.contains(n)) ||
        active.blockedSites.any((s) => !proposed.blockedSites.contains(s));
    _result(m.requestId, ok: true);

    if (tightened != active) {
      policy = tightened;
      _addLog('policy', helper.name, _policyLine(active, tightened));
      _emit(PolicyMessage(policy: policy));
    }
    if (!loosens) return;
    _ask(ConsentKind.policy, '${helper.name} wants Octo to ask you less. OK?', (
      ok,
    ) {
      if (ok == true) {
        final before = policy;
        policy = policy.copyWith(
          askEveryChange: before.askEveryChange && proposed.askEveryChange,
          askBeforeLooking:
              before.askBeforeLooking && proposed.askBeforeLooking,
          never: before.never.where(proposed.never.contains).toList(),
          blockedSites: before.blockedSites
              .where(proposed.blockedSites.contains)
              .toList(),
        );
        _addLog('policy', person, _policyLine(before, policy));
        _emit(PolicyMessage(policy: policy));
      } else {
        _addLog('policy', person, '$person kept the old rule');
        _emit(PolicyMessage(policy: policy, declined: true));
      }
    }, expiresAfter: settings.consentTimeout);
  }

  void _screenRequest(SimHelper helper) {
    _clearHelp();
    _ask(ConsentKind.screen, '${helper.name} wants to see your screen. OK?', (
      ok,
    ) {
      if (ok == true) {
        _addLog('screen', person, '$person showed her screen');
        _emit(
          ScreenMessage(
            ok: true,
            at: _now(),
            screenshot: WireScreenshot.fromWire(sampleScreenDataUri),
            app: 'Microsoft Edge',
            window: 'Inbox – Outlook',
          ),
        );
      } else {
        _addLog('screen', person, '$person said no to showing her screen');
        _emit(const ScreenMessage(ok: false, reason: 'She said no.'));
      }
    }, expiresAfter: settings.consentTimeout);
  }

  void _todoReply(TodoReply m, SimHelper helper) {
    final todo = todos[m.todoId];
    if (todo == null) return;
    _show('${helper.name}: ${m.text}');
    _addLog('message', helper.name, m.text);
    _emitTodo(
      todo.copyWith(
        replies: [
          ...todo.replies,
          Reply(at: _now(), from: helper.name, text: m.text),
        ],
      ),
    );
  }

  void _logRequest(LogRequest m) {
    final since = m.since ?? 0;
    final limit = (m.limit ?? 100).clamp(1, 500);
    final entries = log.where((e) => e.at >= since).take(limit).toList();
    _emit(LogMessage(requestId: m.requestId, entries: entries));
  }

  // ---------------------------------------------------------------------
  // Helpers

  void _ask(
    ConsentKind kind,
    String prompt,
    void Function(bool? ok) onAnswer, {
    Duration? expiresAfter,
    String? taskId,
  }) {
    final consent = PendingConsent._(kind, prompt, onAnswer, taskId);
    _consents.add(consent);
    _show('Octo: $prompt');
    if (settings.autopilot) {
      consent._auto = Timer(settings.momDelay, () => _answer(consent, true));
    }
    if (expiresAfter != null) {
      consent._expiry = Timer(expiresAfter, () => _answer(consent, null));
    }
    _notify();
  }

  void _answerFirst(ConsentKind? kind, bool ok) {
    for (final c in _consents) {
      if (kind == null || c.kind == kind) {
        _answer(c, ok);
        return;
      }
    }
  }

  void _answer(PendingConsent consent, bool? ok) {
    if (!_consents.contains(consent)) return;
    _drop(consent);
    _show(switch (ok) {
      true => '$person tapped OK',
      false => '$person tapped No',
      null => '$person didn\'t answer',
    });
    consent._onAnswer(ok);
    _notify();
  }

  void _drop(PendingConsent consent) {
    consent._auto?.cancel();
    consent._expiry?.cancel();
    _consents.remove(consent);
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    if (!value && _pairing != null) cancelPairing();
    _online.add(value);
    _notify();
  }

  void _clearHelp() {
    if (help == null) return;
    help = null;
    _notify();
  }

  Task _emitTask(Task task) {
    tasks[task.id] = task;
    _emit(TaskMessage(task));
    _notify();
    return task;
  }

  void _emitTodo(Todo todo) {
    todos[todo.id] = todo;
    _emit(TodoMessage(todo));
    _notify();
  }

  void _result(
    String requestId, {
    required bool ok,
    String? taskId,
    String? error,
    String? message,
  }) {
    _emit(
      ResultMessage(
        requestId: requestId,
        ok: ok,
        taskId: taskId,
        error: error,
        message: message,
      ),
    );
  }

  void _emit(HostMessage message) {
    if (_disposed) return;
    _outbound.add(message.toWire());
  }

  void _addLog(
    String kind,
    String by,
    String text, {
    String? taskId,
    String? job,
    String? outcome,
  }) {
    log.add(
      Entry(
        at: _now(),
        kind: kind,
        by: by,
        text: text,
        taskId: taskId,
        job: job,
        outcome: outcome,
      ),
    );
  }

  void _show(String line) {
    momScreen.add(line);
    if (momScreen.length > 50) momScreen.removeAt(0);
    _notify();
  }

  void _notify() {
    if (!_disposed) _changes.add(null);
  }

  int _now() => clock.now().millisecondsSinceEpoch;

  String _hex(int length) => List.generate(
    length,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();

  static List<String> _union(List<String> a, List<String> b) => [
    ...a,
    ...b.where((x) => !a.contains(x)),
  ];

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  static String _changeVerb(ChangeKind kind) => switch (kind) {
    ChangeKind.open => 'open apps',
    ChangeKind.install => 'install apps',
    ChangeKind.signIn => 'sign in',
    ChangeKind.send => 'send messages',
    ChangeKind.delete => 'delete things',
    ChangeKind.settings => 'change settings',
    ChangeKind.call => 'join calls',
    ChangeKind.other || ChangeKind.unknown => 'do that',
  };

  String _policyLine(Policy before, Policy after) {
    if (!before.askEveryChange && after.askEveryChange) {
      return 'Octo will now ask before every change';
    }
    if (before.askEveryChange && !after.askEveryChange) {
      return 'Octo will ask before bigger changes only';
    }
    if (!before.askBeforeLooking && after.askBeforeLooking) {
      return 'Octo will now ask before looking at the screen';
    }
    if (before.askBeforeLooking && !after.askBeforeLooking) {
      return 'Octo can now look at the screen without asking';
    }
    return 'The rules changed';
  }
}

class _Pairing {
  _Pairing({
    required this.helperId,
    required this.name,
    required this.device,
    required this.code,
    required this.expiry,
  });

  final String helperId;
  final String name;
  final String device;
  final String code;
  final Timer expiry;
}
