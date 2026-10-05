import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/auth/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Brief §5.1: one screen, a large Octo, one line, and Sign in with October.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OctoSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: OctoAvatar(size: 160, mood: OctoMood.waiting),
                ),
                const SizedBox(height: OctoSpace.xl),
                Text(
                  l.welcomeLine,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoSpace.xxl),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const SignInSheet(),
                  ),
                  child: Text(l.signInWithOctober),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Email link (or the code from the email), Google, Apple.
class SignInSheet extends ConsumerStatefulWidget {
  const SignInSheet({super.key});

  @override
  ConsumerState<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<SignInSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _withPassword = false;
  String? _sentTo;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthService auth) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authServiceProvider));
    } on AuthException catch (e) {
      if (mounted && !e.cancelled) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    // Signed in: the router takes over; close the sheet.
    ref.listen(signedInAccountProvider, (_, account) {
      if (account != null && mounted) Navigator.of(context).maybePop();
    });
    final sent = _sentTo;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        OctoSpace.xl,
        0,
        OctoSpace.xl,
        MediaQuery.viewInsetsOf(context).bottom + OctoSpace.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.signInWithOctober, style: theme.textTheme.titleLarge),
            const SizedBox(height: OctoSpace.lg),
            if (sent == null) ...[
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(labelText: l.emailLabel),
                onSubmitted: (_) => _withPassword ? null : _sendLink(),
              ),
              if (_withPassword) ...[
                const SizedBox(height: OctoSpace.sm),
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(labelText: l.passwordLabel),
                  onSubmitted: (_) => _signInWithPassword(),
                ),
              ],
              const SizedBox(height: OctoSpace.md),
              FilledButton(
                onPressed: _busy
                    ? null
                    : (_withPassword ? _signInWithPassword : _sendLink),
                child: Text(_withPassword ? l.signInButton : l.sendLink),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _withPassword = !_withPassword),
                child: Text(_withPassword ? l.useEmailLink : l.usePassword),
              ),
            ] else ...[
              Text(l.linkSent(sent)),
              const SizedBox(height: OctoSpace.md),
              TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: l.codeLabel,
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(sent),
              ),
              const SizedBox(height: OctoSpace.md),
              FilledButton(
                onPressed: _busy ? null : () => _verify(sent),
                child: Text(l.signInButton),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: OctoSpace.sm),
              Text(_error!, style: TextStyle(color: colors.needsYou)),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: OctoSpace.md),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OctoSpace.sm,
                    ),
                    child: Text(
                      l.orDivider,
                      style: TextStyle(color: colors.secondaryLabel),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run((auth) => auth.signInWithGoogle()),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text(l.continueGoogle),
            ),
            const SizedBox(height: OctoSpace.sm),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run((auth) => auth.signInWithApple()),
              icon: Icon(Platform.isIOS ? Icons.apple : Icons.apple_outlined),
              label: Text(l.continueApple),
            ),
            if (_busy) ...[
              const SizedBox(height: OctoSpace.md),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  void _sendLink() {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    _run((auth) async {
      await auth.sendEmailLink(email);
      if (mounted) setState(() => _sentTo = email);
    });
  }

  void _signInWithPassword() {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) return;
    _run((auth) => auth.signInWithPassword(email, _password.text));
  }

  void _verify(String email) {
    final code = _code.text.trim();
    if (code.length != 6) return;
    _run((auth) => auth.verifyEmailCode(email, code));
  }
}
