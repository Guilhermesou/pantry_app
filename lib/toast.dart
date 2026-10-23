import 'dart:async';
import 'package:flutter/material.dart';
import 'design.dart';
import 'haptics.dart';
import 'motion.dart';
import 'symbols.dart';

/// Shows a short confirmation at the top of the screen, optionally with "Desfazer".
void showToast(
  BuildContext context,
  String message, {
  VoidCallback? undo,
  bool error = false,
}) => context.findAncestorStateOfType<_ToastHostState>()?.show(
  message,
  undo,
  error,
);

/// Hosts the toast above every route. Its timer is cancelled with the host.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});
  final Widget child;
  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  String message = '';
  VoidCallback? undo;
  bool error = false, visible = false;

  /// Counts errors so each one shakes the toast again.
  int failures = 0;
  Timer? timer;
  void show(String text, VoidCallback? onUndo, bool failed) {
    timer?.cancel();
    if (failed) Haptics.error();
    setState(() {
      if (failed) failures++;
      message = text;
      undo = onUndo;
      error = failed;
      visible = true;
    });
    final long = onUndo != null || failed || text.length > 60;
    timer = Timer(Duration(milliseconds: long ? 4500 : 2600), hide);
  }

  void hide() {
    timer?.cancel();
    if (mounted) setState(() => visible = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned(
        left: 16,
        right: 16,
        top: MediaQuery.paddingOf(context).top + 6,
        // Only "Desfazer" takes touches; otherwise taps reach what is underneath.
        child: IgnorePointer(
          ignoring: !visible || undo == null,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -.3),
            duration: motionTime(context, visible ? 420 : 300),
            curve: visible ? springOut : emphasized,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: motionTime(context, 300),
              curve: emphasized,
              child: Shake(
                trigger: failures,
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: shadowLarge,
                      ),
                      child: Row(
                        children: [
                          // Pops on every new message, like a stamp.
                          BumpOnChange(
                            value: '$message$failures',
                            amount: .25,
                            child: Icon(
                              error ? Symbols.error : Symbols.checkCircle,
                              size: 22,
                              fill: 1,
                              color: error ? danger : success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (undo != null)
                            AppButton(
                              label: 'Desfazer',
                              tone: ButtonTone.soft,
                              height: 32,
                              onPressed: () {
                                final action = undo!;
                                hide();
                                action();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
