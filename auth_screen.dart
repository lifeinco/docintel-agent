import 'dart:async';
import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../theme/di_colors.dart';
import '../theme/di_text.dart';
import '../widgets/di_button.dart';
import '../widgets/di_chip.dart';
import '../widgets/di_icons.dart';

/// MÓDULO 01 · Autenticación del operador (huella en dispositivo).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.operador,
    required this.onDone,
    this.onPin,
  });

  final String operador;
  final VoidCallback onDone;
  final VoidCallback? onPin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Phase { idle, scan, ok }

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  final _timers = <Timer>[];
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _verify() {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.scan);
    _pulse.stop();
    _spin.repeat();
    _timers.add(Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      _spin.stop();
      setState(() => _phase = _Phase.ok);
    }));
    _timers.add(Timer(const Duration(milliseconds: 3100), () {
      if (mounted) widget.onDone();
    }));
  }

  @override
  Widget build(BuildContext context) {
    final t = Tr.of(context);
    final ringColor = _phase == _Phase.ok ? DI.acc : DI.accAlpha(0.45);

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.docintelAgent,
                style: DIType.label.copyWith(letterSpacing: 5.4),
              ),
              const SizedBox(height: 38),
              // sensor de huella
              GestureDetector(
                onTap: _verify,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _spin]),
                  builder: (context, _) {
                    final glow = _phase == _Phase.idle
                        ? (0.5 - (_pulse.value - 0.5).abs()) * 2
                        : 0.0;
                    return Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _phase == _Phase.ok
                            ? DI.accAlpha(0.12)
                            : Colors.transparent,
                        border: Border.all(color: ringColor, width: 1.5),
                        boxShadow: _phase == _Phase.idle
                            ? [
                                BoxShadow(
                                  color: DI.accAlpha(0.28 * glow),
                                  blurRadius: 0,
                                  spreadRadius: 14 * glow,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_phase == _Phase.scan)
                            Transform.rotate(
                              angle: _spin.value * 6.283,
                              child: CustomPaint(
                                size: const Size(148, 148),
                                painter: _ArcPainter(),
                              ),
                            ),
                          if (_phase == _Phase.ok)
                            const DIcon(DIIcon.check, size: 52, color: DI.acc)
                          else
                            DIcon(
                              DIIcon.fingerprint,
                              size: 62,
                              color: _phase == _Phase.scan
                                  ? DI.acc
                                  : DI.accAlpha(0.85),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: 250,
                height: 48,
                child: Center(
                  child: _phase == _Phase.ok
                      ? Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${t.identityConfirmed}\n'),
                            TextSpan(
                              text: widget.operador,
                              style: const TextStyle(
                                color: DI.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                          textAlign: TextAlign.center,
                          style: DIType.bodyMuted.copyWith(fontSize: 15),
                        )
                      : Text(
                          _phase == _Phase.idle
                              ? t.authHint
                              : t.verifyingFingerprint,
                          textAlign: TextAlign.center,
                          style: DIType.bodyMuted.copyWith(fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              DIChip(
                tone: DIChipTone.acc,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DIDot(DI.acc),
                    const SizedBox(width: 7),
                    Text(t.fieldModeOffline),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
          child: Column(
            children: [
              DIButton(
                label: switch (_phase) {
                  _Phase.idle => t.verifyIdentity,
                  _Phase.scan => t.verifying,
                  _Phase.ok => t.accessGranted,
                },
                disabled: _phase != _Phase.idle,
                onPressed: _verify,
              ),
              if (widget.onPin != null && _phase == _Phase.idle) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.onPin,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      t.signInWithPin,
                      textAlign: TextAlign.center,
                      style: DIType.body.copyWith(
                          color: DI.acc, fontSize: 14.5),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'v2.1.0 · ML KIT · FLUTTER',
                style: DIType.monoSmall
                    .copyWith(letterSpacing: 1.4, color: DI.muted.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DI.acc
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 1.25,
    );
    canvas.drawArc(rect, 0, 1.7, false, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
