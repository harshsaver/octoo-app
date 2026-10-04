import 'dart:async';

import 'app_message.dart';
import 'host_message.dart';

enum RequestFailureKind {
  /// No reply within the timeout, counted from when the request was sent.
  timeout,

  /// The connection ended first. The request may still have reached her
  /// computer; a late `result` arrives as an unmatched message.
  disconnected,

  /// `send` threw. Whether the request left the phone is unknown; [cause]
  /// says why.
  sendFailed,

  /// A reply with this `requestId` arrived but didn't parse.
  malformedReply,
}

class RequestFailure implements Exception {
  const RequestFailure(this.kind, this.requestId, [this.cause]);

  final RequestFailureKind kind;
  final String requestId;
  final Object? cause;

  @override
  String toString() => 'RequestFailure(${kind.name}, $requestId)';
}

/// Matches replies to requests on one connection.
///
/// Create one per connection (epoch) and [close] it when the connection
/// ends. A reply matches when it has the request's `requestId` and either the
/// expected type or `result` (her computer may answer any request with an
/// error `result`). Anything else, including a late reply to a request that
/// already timed out, is left for the caller: [offer] returns false.
class RequestMatcher {
  RequestMatcher({this.defaultTimeout = const Duration(seconds: 20)});

  final Duration defaultTimeout;
  final Map<String, _Pending> _pending = {};
  bool _closed = false;

  bool get isClosed => _closed;

  int get outstanding => _pending.length;

  /// Registers [request], then calls [send], and completes with the reply.
  /// The timeout starts once [send] completes. Fails with [RequestFailure].
  Future<HostReply> request(
    AppRequest request,
    Future<void> Function() send, {
    Duration? timeout,
  }) {
    final id = request.requestId;
    if (_closed) {
      return Future.error(RequestFailure(RequestFailureKind.disconnected, id));
    }
    if (_pending.containsKey(id)) {
      throw StateError('requestId already outstanding');
    }
    final pending = _Pending(request.expects);
    _pending[id] = pending;
    final future = pending.completer.future;
    unawaited(_dispatch(id, pending, send, timeout ?? defaultTimeout));
    return future;
  }

  Future<void> _dispatch(
    String id,
    _Pending pending,
    Future<void> Function() send,
    Duration timeout,
  ) async {
    try {
      await send();
    } catch (e) {
      _fail(id, pending, RequestFailureKind.sendFailed, e);
      return;
    }
    if (_pending[id] != pending) return; // answered or closed during send
    pending.timer = Timer(timeout, () {
      _fail(id, pending, RequestFailureKind.timeout);
    });
  }

  /// Offers an incoming message. Returns true if it answered (or, malformed,
  /// failed) an outstanding request; false means the caller should handle it.
  bool offer(HostMessage message) {
    switch (message) {
      case HostReply(:final requestId?):
        final pending = _pending[requestId];
        if (pending == null) return false;
        if (message.type != pending.expects.type && message is! ResultMessage) {
          return false;
        }
        _pending.remove(requestId);
        pending.timer?.cancel();
        pending.completer.complete(message);
        return true;
      case UnknownHostMessage(
        :final requestId?,
        reason: UnknownReason.malformed,
      ):
        final pending = _pending[requestId];
        if (pending == null) return false;
        if (message.type != pending.expects.type && message.type != 'result') {
          return false;
        }
        _fail(requestId, pending, RequestFailureKind.malformedReply);
        return true;
      default:
        return false;
    }
  }

  /// Ends this connection: every outstanding request fails as
  /// [RequestFailureKind.disconnected], and new requests fail at once.
  void close() {
    _closed = true;
    for (final entry in _pending.entries.toList()) {
      _fail(entry.key, entry.value, RequestFailureKind.disconnected);
    }
  }

  void _fail(
    String id,
    _Pending pending,
    RequestFailureKind kind, [
    Object? cause,
  ]) {
    if (_pending[id] != pending) return;
    _pending.remove(id);
    pending.timer?.cancel();
    pending.completer.completeError(RequestFailure(kind, id, cause));
  }
}

class _Pending {
  _Pending(this.expects);

  final ReplyKind expects;
  final Completer<HostReply> completer = Completer<HostReply>();
  Timer? timer;
}
