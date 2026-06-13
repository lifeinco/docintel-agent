import 'package:flutter/material.dart';
import 'di_colors.dart';
import 'di_text.dart';

/// ThemeData global DocIntel (dark, esmeralda). Material3 con la paleta y
/// tipografía LIFE·IN·CO aplicadas a los controles del sistema.
ThemeData buildDITheme() {
  const scheme = ColorScheme.dark(
    primary: DI.acc,
    onPrimary: DI.accOn,
    secondary: DI.acc,
    surface: DI.panel,
    onSurface: DI.text,
    error: DI.warn,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DI.bg,
    colorScheme: scheme,
    fontFamily: DIType.sans,
    splashColor: DI.accAlpha(0.10),
    highlightColor: DI.accAlpha(0.06),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: DI.acc,
      selectionColor: Color(0x552FBF8F),
      selectionHandleColor: DI.acc,
    ),
    iconTheme: const IconThemeData(color: DI.text),
  );
}
