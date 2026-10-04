import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/providers.dart';
import '../../data/backend/octo_backend.dart';
import '../../data/enrollment/enrollment_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/tokens.dart';
import 'setup_sheet.dart';

/// Adding an Octo (brief §5.3): the camera opens at once, with a rounded
/// scanning frame, "Type the code instead", and the small print.
class AddOctoScreen extends ConsumerStatefulWidget {
  const AddOctoScreen({super.key, this.initialPayload});

  /// From a universal link (`/octo/add#…`); held only in memory.
  final String? initialPayload;

  @override
  ConsumerState<AddOctoScreen> createState() => _AddOctoScreenState();
}

class _AddOctoScreenState extends ConsumerState<AddOctoScreen> {
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;
  late final bool _camera = ref.read(cameraAvailableProvider);

  @override
  void initState() {
    super.initState();
    _camera; // read while mounted
    final payload = widget.initialPayload;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start(payload));
    }
  }

  @override
  void dispose() {
    if (_camera) unawaited(_scanner.dispose());
    super.dispose();
  }

  Future<void> _start(String payload) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_camera) unawaited(_scanner.stop());
    final l = AppLocalizations.of(context);
    try {
      final enrollment = await ref.read(enrollmentProvider).resolve(payload);
      if (enrollment.mode == EnrollmentMode.owner) {
        await ref
            .read(backendProvider)
            .claim(enrollId: enrollment.enrollId, secret: enrollment.secret);
      }
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
      final computerId = await SetupSheet.show(context, enrollment);
      if (!mounted) return;
      if (computerId != null) {
        context.pushReplacement('/octo/$computerId');
        return;
      }
    } on EnrollmentException {
      _snack(l.codeNotRecognised);
    } on BackendException catch (e) {
      _snack(l.setupFailed(e.message));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (_camera) unawaited(_scanner.start());
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _typeCode() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TypeCodeSheet(),
    );
    if (code != null) await _start(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFake = ref.watch(appConfigProvider).isFake;
    final size = MediaQuery.sizeOf(context);
    final frame = (size.shortestSide * 0.7).clamp(200.0, 320.0);
    const onCamera = Colors.white;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!_camera)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(OctoSpace.xl),
                child: Text(
                  l.cameraUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: onCamera),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _scanner,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  final value = b.rawValue;
                  if (value != null && value.isNotEmpty) {
                    unawaited(_start(value));
                    return;
                  }
                }
              },
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(OctoSpace.xl),
                  child: Text(
                    l.cameraUnavailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: onCamera),
                  ),
                ),
              ),
            ),
          // Scrims keep the caption and buttons readable over any camera image.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.3, 0.6, 1],
              ),
            ),
          ),
          Center(
            child: Container(
              width: frame,
              height: frame,
              decoration: BoxDecoration(
                border: Border.all(color: onCamera, width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: l.close,
                    color: onCamera,
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: OctoSpace.xl),
                  child: Text(
                    l.scanCaption,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onCamera,
                      shadows: const [Shadow(blurRadius: 6)],
                    ),
                  ),
                ),
                const Spacer(),
                if (_busy) const CircularProgressIndicator.adaptive(),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: onCamera),
                  onPressed: _busy ? null : _typeCode,
                  child: Text(l.typeCodeInstead),
                ),
                if (isFake)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: onCamera),
                    onPressed: _busy ? null : () => _start(_simPayload()),
                    child: Text(l.useSimulator),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OctoSpace.xl,
                    OctoSpace.sm,
                    OctoSpace.xl,
                    OctoSpace.lg,
                  ),
                  child: Text(
                    l.smallPrint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: onCamera),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _simPayload() {
    const names = ["Mom's laptop", "Dad's PC", "Grandma's iMac"];
    final count = ref.read(computersProvider).value?.length ?? 0;
    return 'octo-sim:${names[count % names.length]}';
  }
}

/// "Type the code instead": an 8-character field. Owns its controller.
class _TypeCodeSheet extends StatefulWidget {
  const _TypeCodeSheet();

  @override
  State<_TypeCodeSheet> createState() => _TypeCodeSheetState();
}

class _TypeCodeSheetState extends State<_TypeCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final valid = normaliseTypedCode(_controller.text) != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        OctoSpace.xl,
        0,
        OctoSpace.xl,
        MediaQuery.viewInsetsOf(context).bottom + OctoSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.typeCodeTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OctoSpace.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 9,
            textCapitalization: TextCapitalization.characters,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(letterSpacing: 4),
            decoration: InputDecoration(
              hintText: l.typeCodeHint,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) {
              if (valid) Navigator.pop(context, v);
            },
          ),
          const SizedBox(height: OctoSpace.lg),
          FilledButton(
            onPressed: valid
                ? () => Navigator.pop(context, _controller.text)
                : null,
            child: Text(l.continueLabel),
          ),
        ],
      ),
    );
  }
}
