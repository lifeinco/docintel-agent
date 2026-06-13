import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/record.dart';
import 'i18n/app_strings.dart';
import 'state/app_state.dart';
import 'theme/di_colors.dart';
import 'theme/di_theme.dart';
import 'widgets/di_chrome.dart';
import 'widgets/di_status.dart';
import 'screens/auth_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/source_sheet.dart';
import 'screens/capture_screen.dart';
import 'screens/import_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/form_screen.dart';
import 'screens/success_screen.dart';
import 'screens/records_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/review_screen.dart';
import 'screens/review_detail_screen.dart';
import 'screens/profile_screen.dart';

class DocIntelApp extends StatelessWidget {
  const DocIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocIntel Agent',
      debugShowCheckedModeBanner: false,
      theme: buildDITheme(),
      home: const AppShell(),
    );
  }
}

enum _Phase { auth, pin, app }

/// Pantallas modales (full-screen, sin barra de pestañas).
enum _Modal {
  capture,
  importDoc,
  preview,
  form,
  success,
  recordDetail,
  reviewDetail,
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  _Phase _phase = _Phase.auth;
  String _tab = 'home';
  _Modal? _modal;

  String _fuente = 'camara';
  FieldRecord? _last;
  String? _detailId;
  String? _reviewId;

  void _openCapture() async {
    final src = await showSourceSheet(context);
    if (src == null || !mounted) return;
    setState(() {
      _fuente = src;
      _modal = src == 'camara' ? _Modal.capture : _Modal.importDoc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(fieldProvider);
    final lang = ref.watch(langProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070D0C),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final Widget body;
    final bool showBar; // barra conectividad superior
    final bool showTabs;

    if (_phase == _Phase.auth) {
      showBar = false;
      showTabs = false;
      body = AuthScreen(
        operador: st.operador,
        onDone: () => setState(() => _phase = _Phase.app),
        onPin: () => setState(() => _phase = _Phase.pin),
      );
    } else if (_phase == _Phase.pin) {
      showBar = true;
      showTabs = false;
      body = PinScreen(
        operador: st.operador,
        onBack: () => setState(() => _phase = _Phase.auth),
        onDone: () => setState(() => _phase = _Phase.app),
      );
    } else if (_modal != null) {
      showBar = true;
      showTabs = false;
      body = _buildModal(st);
    } else {
      showBar = true;
      showTabs = true;
      body = _buildTab();
    }

    return AppLocale(
      tr: Tr(lang),
      child: Scaffold(
      backgroundColor: DI.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: showBar
                  ? () => ref
                      .read(fieldProvider.notifier)
                      .setOnline(!st.online)
                  : null,
              child: DIConnectivityBar(online: _phase == _Phase.auth ? false : st.online),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('$_phase-$_tab-$_modal-$_detailId-$_reviewId'),
                  child: body,
                ),
              ),
            ),
            if (showTabs)
              DITabBar(
                current: _tab,
                reviewCount: st.enRevision,
                onCapture: _openCapture,
                onTab: (t) => setState(() => _tab = t),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 'records':
        return RecordsScreen(onRecord: _openRecord);
      case 'review':
        return ReviewScreen(onOpen: _openReview);
      case 'profile':
        return ProfileScreen(onLogout: _logout);
      default:
        return HomeScreen(
          onVerTodos: () => setState(() => _tab = 'records'),
          onRecord: _openRecord,
        );
    }
  }

  Widget _buildModal(FieldState st) {
    switch (_modal!) {
      case _Modal.capture:
        return CaptureScreen(
          onBack: () => setState(() => _modal = null),
          onDone: () => setState(() => _modal = _Modal.preview),
        );
      case _Modal.importDoc:
        return ImportScreen(
          fuente: _fuente,
          onBack: () => setState(() => _modal = null),
          onDone: () => setState(() => _modal = _Modal.preview),
        );
      case _Modal.preview:
        return PreviewScreen(
          fuente: _fuente,
          onRetry: () => setState(() =>
              _modal = _fuente == 'camara' ? _Modal.capture : _Modal.importDoc),
          onAccept: () => setState(() => _modal = _Modal.form),
        );
      case _Modal.form:
        return FormScreen(
          onBack: () => setState(() => _modal = _Modal.preview),
          onSaved: (r) => setState(() {
            _last = r;
            _modal = _Modal.success;
          }),
        );
      case _Modal.success:
        return SuccessScreen(
          record: _last ?? st.records.last,
          online: st.online,
          onNueva: () {
            setState(() => _modal = null);
            _openCapture();
          },
          onVerRegistro: () => setState(() {
            _detailId = (_last ?? st.records.last).id;
            _modal = _Modal.recordDetail;
          }),
          onPanel: () => setState(() {
            _modal = null;
            _tab = 'home';
          }),
        );
      case _Modal.recordDetail:
        return RecordDetailScreen(
          recordId: _detailId!,
          onBack: () => setState(() => _modal = null),
          onReview: _openReview,
        );
      case _Modal.reviewDetail:
        return ReviewDetailScreen(
          recordId: _reviewId!,
          onBack: () => setState(() => _modal = null),
          onApproved: () => setState(() => _modal = null),
        );
    }
  }

  void _openRecord(String id) =>
      setState(() {
        _detailId = id;
        _modal = _Modal.recordDetail;
      });

  void _openReview(String id) => setState(() {
        _reviewId = id;
        _modal = _Modal.reviewDetail;
      });

  void _logout() {
    ref.read(fieldProvider.notifier).logout();
    setState(() {
      _phase = _Phase.auth;
      _tab = 'home';
      _modal = null;
    });
  }
}
