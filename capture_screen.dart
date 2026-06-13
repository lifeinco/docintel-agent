import 'dart:async';
import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../theme/di_colors.dart';
import '../theme/di_text.dart';
import '../widgets/di_chip.dart';
import '../widgets/di_chrome.dart';
import '../widgets/di_icons.dart';

/// MÓDULO 02 · Captura del acta (OCR en tiempo real, simulado offline).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.onBack, required this.onDone});

  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

const _kChecks = 3;
const _kOcrLines = 5;

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  int _done = 0;
  int _lines = 0;
  bool _proc = false;
  final _timers = <Timer>[];
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _kChecks; i++) {
      _timers.add(Timer(Duration(milliseconds: 800 + i * 700), () {
        if (mounted) setState(() => _done = i + 1);
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _scan.dispose();
    super.dispose();
  }

  bool get _ready => _done >= _kChecks;

  void _capture() {
    if (!_ready || _proc) return;
    setState(() => _proc = true);
    _scan.stop();
    for (var i = 0; i < _kOcrLines; i++) {
      _timers.add(Timer(Duration(milliseconds: 350 + i * 480), () {
        if (mounted) setState(() => _lines = i + 1);
      }));
    }
    _timers.add(Timer(
      Duration(milliseconds: 350 + _kOcrLines * 480 + 650),
      () {
        if (mounted) widget.onDone();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Tr.of(context);
    final checks = [t.chkPixels, t.chkLight, t.chkAngle];
    final ocrLines = t.ocrLines;
    return Column(
      children: [
        DIModuleHeader(
          tag: t.module02,
          title: t.captureTitle,
          onBack: widget.onBack,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
            child: Column(
              children: [
                // visor
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0C1514), Color(0xFF080F0E)],
                        ),
                        border: Border.all(color: DI.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // esquinas
                          ..._corners(),
                          // scanline (Positioned.fill + Align para evitar
                          // Positioned dentro de un builder)
                          if (!_proc)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _scan,
                                builder: (context, _) => Align(
                                  alignment:
                                      Alignment(0, _scan.value * 1.88 - 0.94),
                                  child: Container(
                                    width: double.infinity,
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 30),
                                    decoration: BoxDecoration(
                                      color: DI.accAlpha(0.65),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: DI.accAlpha(0.5),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!_proc)
                            Center(
                              child: Text(
                                _ready
                                    ? t.docAligned
                                    : t.aimAtDoc,
                                style: DIType.chip
                                    .copyWith(color: DI.muted, fontSize: 13),
                              ),
                            ),
                          // salida OCR
                          if (_proc)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 34),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < _lines; i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 13),
                                        child: _OcrLine(
                                            text: ocrLines[i], head: i == 0),
                                      ),
                                    if (_lines >= _kOcrLines)
                                      Text(t.sendingToForm,
                                          style: DIType.chip.copyWith(
                                              color: DI.muted, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DIChip(
                  tone: DIChipTone.solid,
                  expand: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('◉ ', style: TextStyle(color: DI.acc)),
                      Text(t.mlKitChip),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < checks.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      DIChip(
                        tone: i < _done
                            ? DIChipTone.acc
                            : DIChipTone.neutral,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (i < _done)
                              const DIcon(DIIcon.check, size: 10, color: DI.acc)
                            else
                              const DIDot(DI.border2, size: 6),
                            const SizedBox(width: 7),
                            Text(checks[i]),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // obturador
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
          child: GestureDetector(
            onTap: _capture,
            child: AnimatedOpacity(
              opacity: _proc ? 0.35 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DI.text,
                  border: Border.all(color: DI.bg, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _ready && !_proc ? DI.acc : DI.border2,
                      spreadRadius: 2,
                    ),
                    if (_ready && !_proc)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: const Center(
                  child: DIcon(DIIcon.camera, size: 22, color: Color(0xFF0A1110)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _corners() {
    const len = 34.0;
    const inset = 18.0;
    Widget c(
            {double? top,
            double? left,
            double? right,
            double? bottom,
            required bool t,
            required bool l,
            required bool r,
            required bool b}) =>
        Positioned(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
          child: Container(
            width: len,
            height: len,
            decoration: BoxDecoration(
              border: Border(
                top: t ? const BorderSide(color: DI.acc, width: 2.5) : BorderSide.none,
                left: l ? const BorderSide(color: DI.acc, width: 2.5) : BorderSide.none,
                right: r ? const BorderSide(color: DI.acc, width: 2.5) : BorderSide.none,
                bottom: b ? const BorderSide(color: DI.acc, width: 2.5) : BorderSide.none,
              ),
            ),
          ),
        );
    return [
      c(top: inset, left: inset, t: true, l: true, r: false, b: false),
      c(top: inset, right: inset, t: true, r: true, l: false, b: false),
      c(bottom: inset, left: inset, b: true, l: true, t: false, r: false),
      c(bottom: inset, right: inset, b: true, r: true, t: false, l: false),
    ];
  }
}

class _OcrLine extends StatelessWidget {
  const _OcrLine({required this.text, required this.head});
  final String text;
  final bool head;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!head) ...[
            const DIcon(DIIcon.check, size: 11, color: DI.acc),
            const SizedBox(width: 9),
          ],
          Text(
            text,
            style: DIType.chip.copyWith(
              color: head ? DI.muted : DI.acc,
              fontSize: head ? 11.5 : 13.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
