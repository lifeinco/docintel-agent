import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../data/record.dart';
import '../i18n/app_strings.dart';
import '../theme/di_colors.dart';
import '../theme/di_text.dart';
import '../widgets/di_chip.dart';
import '../widgets/di_chrome.dart';
import '../widgets/di_icons.dart';
import '../widgets/di_status.dart';

/// Panel de campo · Operaciones del día.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onVerTodos,
    required this.onRecord,
  });

  final VoidCallback onVerTodos;
  final void Function(String id) onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(fieldProvider);
    final notifier = ref.read(fieldProvider.notifier);
    final recientes = st.records.reversed.take(4).toList();
    final t = Tr.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DIModuleHeader(tag: t.fieldPanel, title: t.todaysOps),

        // banner conectividad + sync
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: st.online ? DI.accAlpha(0.07) : DI.panel,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: st.online ? DI.accAlpha(0.35) : DI.border2),
            ),
            child: Row(
              children: [
                DIcon(DIIcon.sync,
                    size: 15, color: st.online ? DI.acc : DI.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    st.syncing
                        ? t.syncingRecords
                        : st.online
                            ? (st.pendientes > 0
                                ? t.onlineQueued(st.pendientes)
                                : t.onlineUpToDate)
                            : t.offlineQueue(st.pendientes),
                    style: DIType.chip.copyWith(
                        color: st.online ? DI.acc : DI.muted, fontSize: 11.5),
                  ),
                ),
                if (st.online && st.pendientes > 0 && !st.syncing)
                  GestureDetector(
                    onTap: notifier.syncPending,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: DI.acc, borderRadius: BorderRadius.circular(8)),
                      child: Text(t.sync,
                          style: DIType.body.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: DI.accOn)),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // tarjeta operador
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: DI.panel,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: DI.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DI.accAlpha(0.45)),
                  ),
                  child:
                      const Center(child: DIcon(DIIcon.user, size: 18, color: DI.acc)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.operador,
                          style: DIType.body.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(t.opZone, style: DIType.monoSmall),
                    ],
                  ),
                ),
                DIChip(tone: DIChipTone.acc, child: Text(t.active)),
              ],
            ),
          ),
        ),

        // métricas
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
          child: Row(
            children: [
              _metric(st.total.toString(), t.records, false),
              const SizedBox(width: 10),
              _metric(st.pendientes.toString(), t.queued, false),
              const SizedBox(width: 10),
              _metric(st.enRevision.toString(), t.review, st.enRevision > 0),
            ],
          ),
        ),

        // recientes
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.recent,
                        style: DIType.label.copyWith(letterSpacing: 2.2)),
                    GestureDetector(
                      onTap: onVerTodos,
                      child: Row(
                        children: [
                          Text(t.viewAll,
                              style: DIType.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DI.acc)),
                          const SizedBox(width: 3),
                          const DIcon(DIIcon.chevronR, size: 14, color: DI.acc),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: recientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = recientes[i];
                      return GestureDetector(
                        onTap: () => onRecord(r.id),
                        child: _RecordTile(r: r),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String value, String label, bool warn) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
          decoration: BoxDecoration(
            color: DI.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: warn ? DI.err.withValues(alpha: 0.35) : DI.border),
          ),
          child: Column(
            children: [
              Text(value,
                  style: DIType.metric.copyWith(
                      fontSize: 23, color: warn ? DI.err : DI.text)),
              const SizedBox(height: 4),
              Text(label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: DIType.label.copyWith(fontSize: 9.5, letterSpacing: 1.2)),
            ],
          ),
        ),
      );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.r});
  final FieldRecord r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: DI.panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DI.border),
      ),
      child: Row(
        children: [
          const DIcon(DIIcon.doc, size: 16, color: DI.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DIType.itemTitle),
                const SizedBox(height: 2),
                Text('${r.id} · ${r.municipio} · ${r.hora}',
                    style: DIType.monoSmall.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DIEstado(status: r.status),
        ],
      ),
    );
  }
}
