import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/record.dart';
import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../theme/di_colors.dart';
import '../theme/di_text.dart';
import '../widgets/di_chrome.dart';
import '../widgets/di_icons.dart';

/// MÓDULO 05 · Revisión humana (HITL) — cola de campos de baja confianza.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.onOpen});
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(fieldProvider);
    final t = Tr.of(context);
    final cola =
        st.records.reversed.where((r) => r.status == RecordStatus.revision).toList();

    return Column(
      children: [
        DIModuleHeader(tag: t.module05, title: t.humanReview),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
          child: Text(
            t.reviewIntro,
            style: DIType.bodyMuted.copyWith(fontSize: 13, height: 1.55),
          ),
        ),
        Expanded(
          child: cola.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DI.accAlpha(0.40), width: 1.5),
                        ),
                        child: const Center(
                            child: DIcon(DIIcon.check, size: 24, color: DI.acc)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.queueClear,
                        textAlign: TextAlign.center,
                        style: DIType.bodyMuted.copyWith(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 8),
                  itemCount: cola.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, i) {
                    final r = cola[i];
                    final flag = r.flags.isNotEmpty ? r.flags.first : null;
                    return GestureDetector(
                      onTap: () => onOpen(r.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          color: DI.panel,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DI.err.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: DI.err.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                  child:
                                      DIcon(DIIcon.alert, size: 17, color: DI.err)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.nombre, style: DIType.itemTitle),
                                  const SizedBox(height: 3),
                                  Text(
                                    flag != null
                                        ? '${r.id} · ${localizedField(t, flag.campo)} · OCR ${flag.conf}'
                                        : '${r.id} · ${t.uncertainField}',
                                    style: DIType.monoSmall
                                        .copyWith(fontSize: 10.5, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const DIcon(DIIcon.chevronR, size: 16, color: DI.muted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
