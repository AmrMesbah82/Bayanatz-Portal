// ═══════════════════════════════════════════════════════════════════════════
// AutoCloseDialog — 29/9/2026
//
// App-wide rule: every MESSAGE dialog (success / error / info / validation)
// appears and closes itself after 3 seconds — no "OK" button to press.
//
// Wrap the dialog widget returned by a showDialog builder:
//
//   showDialog(
//     context: context,
//     builder: (_) => AutoCloseDialog(child: Dialog(...)),
//   );
//
// Dialogs that ask for a decision or input (confirm / delete / filters /
// forms / export options) are NOT wrapped — they wait for the user.
// Tapping outside still closes a message dialog early.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';

/// How long a message dialog stays on screen.
const Duration kAutoCloseDialogDuration = Duration(seconds: 3);

class AutoCloseDialog extends StatefulWidget {
  const AutoCloseDialog({
    super.key,
    required this.child,
    this.duration = kAutoCloseDialogDuration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<AutoCloseDialog> createState() => _AutoCloseDialogState();
}

class _AutoCloseDialogState extends State<AutoCloseDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _close);
  }

  void _close() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return; // already closed
    final nav = Navigator.of(context);
    if (route.isCurrent) {
      nav.pop();
    } else {
      // Something opened on top of it — remove just this dialog.
      nav.removeRoute(route);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
