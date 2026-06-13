# DocIntel Agent · App de captura de campo — LIFE·IN·CO

**Producto estrella de LIFE·IN·CO.** App operadora offline-first para captura,
validación con IA y revisión humana de documentos de programas sociales,
auditoría, interventoría, fiduciario y notarías. Identidad visual canónica
LIFE·IN·CO (navy esmeralda · Space Grotesk · IBM Plex Mono).

---

## El modelo de negocio que materializa

DocIntel captura el **volumen documental** de los procesos intensivos en
documentos (no los programas en sí). Esta app es el paso 01 — la captura en
campo — que alimenta el pipeline: OCR → validación lógica → agentes de
cumplimiento/antifraude/impacto → base de datos auditable.

---

## Funcionalidades (flujo completo de 5 módulos + navegación corporativa)

**Autenticación**
- **Módulo 01 · Huella** — biometría en el dispositivo.
- **Módulo 01 · PIN** — login alterno de 4 dígitos para **dispositivos compartidos**.

**Captura (Módulo 02)**
- **Hoja de origen** — cámara · galería · PDF (documento recibido por correo/WhatsApp).
- **Cámara con OCR en vivo** — visor con encuadre, scanline y checks (nitidez/luz/ángulo).
- **Importar** — elegir foto de galería o archivo PDF, procesado on-device.
- **Verificación de legibilidad** — control de calidad ("¿es legible?") antes de extraer:
  nitidez, encuadre, OCR, con opción de repetir.

**Datos (Módulo 03)**
- Campos precargados por OCR con **confianza por campo** (resalta < 90% en ámbar).
- GPS obligatorio + guardado local cifrado AES-256.

**Sincronización & registros (Módulo 04)**
- Lista filtrable (Todos · En cola · Sincronizados · Revisión) + sync manual.
- **Detalle de registro**: documento, **veredicto IA** (Cumple % · agentes de
  Cumplimiento/Antifraude/Impacto), **traza de auditoría** (timeline), datos.
- Estados con color: **EN COLA** (ámbar) · **SUBIENDO** · **SINCRONIZADO** (azul) ·
  **VALIDADO IA** (verde) · **REVISIÓN** (rojo).

**Revisión humana / HITL (Módulo 05)**
- Cola de campos de baja confianza con badge en la navegación.
- Detalle con **recorte del documento** resaltando la zona dudosa, campo editable,
  y nota de **active learning** (cada corrección reentrena el OCR).
- Aprobar/corregir → el registro pasa a VALIDADO IA y sale de la cola.

**Perfil / Operador y dispositivo**
- Sincronización automática (toggle), cifrado local, GPS, última sync, versión.
- **Idioma ES/EN** — control segmentado que cambia toda la app al instante
  (operadores en campo en español; demos a Google/inversionistas en inglés).
  La preferencia se guarda en el dispositivo. Por defecto: Español.
- Cerrar sesión.

**Navegación corporativa** — barra inferior Inicio · Registros · **[Captura]** ·
Revisión (con contador) · Perfil. Toca la barra superior (SIN RED ⇄ LTE) para ver
la sincronización en vivo (control de demo).

---

## Stack técnico — cómo quedó

| Capa | Tecnología | Producto Google |
|---|---|---|
| **Frontend** | Flutter (Android · iOS) · Riverpod · Space Grotesk + IBM Plex Mono | ✅ Flutter |
| **OCR on-device** | ML Kit (captura offline en campo) | ✅ ML Kit |
| **OCR / IA backend** | Gemini 2.5 Flash (volumen) + Pro (alto riesgo) | ✅ Vertex AI · Gemini |
| **Agentes** | Cumplimiento · Antifraude · Impacto | ✅ Vertex AI Agent Builder |
| **OCR documental** | Texto nativo (pdfplumber) + escaneado (Gemini) | ✅ Document AI |
| **Backend** | FastAPI · Cloud Run · JWT | ✅ Cloud Run |
| **Base de datos** | PostgreSQL / AlloyDB (optimizada para IA generativa) | ✅ AlloyDB |
| **Almacenamiento** | imágenes/PDF de documentos | ✅ Cloud Storage |
| **Analítica** | métricas de volumen y calidad | ✅ BigQuery |

La app es **offline-first**: captura sin señal, cola local cifrada, sincroniza al
reconectar. Todo el procesamiento de IA corre en Google Cloud.

### Listo para producción (no solo demo)
El `ApiClient` (`lib/data/api_client.dart`) ya implementa los endpoints reales:
`/auth/login`, `/auth/pin`, `/documents/upload` (OCR), `/field/records`,
`/hitl/{id}/review`. **Para conectarlo a producción:** define `API_BASE_URL` en
`flutter_app/.env` con la URL de tu Cloud Run. Sin esa variable corre en modo demo
(fiel al flujo) y al ponerla pasa a producción **sin cambiar una línea de código**.

---

## Probarlo en el celular (tú y tu papá)

1. Copia **`DocIntel-Agent.apk`** al teléfono (WhatsApp · USB · Drive).
2. Ábrelo → permite "instalar de esta fuente" → Instalar.
3. Abre **DocIntel Agent**. No necesita internet ni cuenta.
   - **Huella:** toca el sensor → "Verificar identidad".
   - **PIN:** "Ingresar con PIN" → cualquier PIN ≠ 0000 (0000 simula error).
   - **Capturar:** botón central [+] → elige origen → procesa → revisa → guarda.
   - **Revisión:** pestaña Revisión → abre el caso → corrige/aprueba.
   - **Sincronizar:** toca la barra superior (SIN RED → LTE).

> APK firmado con la clave debug de Android (suficiente para probar entre ustedes).
> Para Play Store / distribución formal se genera una keystore propia.

---

## Verificado (2026-06-13, emulador Pixel 6 · Android 14)

Recorrido pantalla por pantalla del flujo completo (PIN → panel → revisión HITL →
aprobación → estados IA) + **7/7 tests** automáticos (`flutter test`) ·
`flutter analyze` sin errores.

## Scripts (carpeta raíz)
`BUILD_APK_RELEASE.bat` (genera el APK) · `RUN_EMU.bat` (emulador) ·
`ANALYZE.bat` · `TEST.bat` · `START_BACKEND.bat` (backend FastAPI).
