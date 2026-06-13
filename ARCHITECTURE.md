# DocIntel Agent — Arquitectura Completa
> Stack: Flutter (Android + iOS) · FastAPI · AlloyDB · Gemini 1.5 · VertexAI · MLKit · Cloud Run

---

## 1. VISIÓN DEL SISTEMA

```
┌─────────────────────────────────────────────────────┐
│                  Flutter App                        │
│   Android + iOS  ·  Riverpod  ·  go_router          │
│                                                     │
│  [Scanner] → [Queue] → [HITL Review] → [Dashboard]  │
│                   ↕ REST/JSON                       │
│          ┌────────────────────────┐                 │
│          │   FastAPI Backend      │                 │
│          │   Cloud Run            │                 │
│          │   JWT · RLS · RBAC     │                 │
│          └────────┬───────────────┘                 │
│        ┌──────────┼──────────┐                      │
│    AlloyDB    Cloud Storage  Gemini+VertexAI         │
│   (PostgreSQL)  (PDFs/imgs)  (OCR/Embeddings)        │
└─────────────────────────────────────────────────────┘
```

---

## 2. TECH STACK COMPLETO

### Flutter App
| Capa | Paquete | Versión |
|------|---------|---------|
| State | hooks_riverpod | ^2.5.1 |
| Navigation | go_router | ^14.2.0 |
| HTTP | dio + retrofit | ^5.4.3 + ^4.1.0 |
| Code gen | freezed + json_serializable | ^2.4.6 + ^6.7.1 |
| DI | get_it + injectable | ^7.6.7 + ^2.3.2 |
| Local cache | isar + isar_flutter_libs | ^3.1.0 |
| Auth storage | flutter_secure_storage | ^9.0.0 |
| Camera | camera | ^0.11.0 |
| Scanner | google_mlkit_document_scanner | ^0.1.0 |
| OCR on-device | google_mlkit_text_recognition | ^0.13.0 |
| Image | flutter_image_compress + image | ^2.1.0 |
| Charts | fl_chart | ^0.68.0 |
| PDF export | pdf | ^3.11.0 |
| Excel export | excel | ^4.0.2 |
| Share | share_plus | ^10.0.0 |
| File mgmt | path_provider + open_filex | ^2.3.0 |
| Lottie | lottie | ^3.1.0 |
| Connectivity | connectivity_plus | ^6.0.3 |
| Build runner | build_runner | ^2.4.9 |

### Backend
| Componente | Tecnología |
|------------|------------|
| Framework | FastAPI 0.111 + uvicorn |
| ORM | SQLAlchemy 2.x async |
| Migrations | Alembic |
| DB | AlloyDB (PostgreSQL 15) via asyncpg |
| Auth | python-jose (JWT) + passlib (bcrypt) |
| AI OCR | google-generativeai (Gemini 1.5 Flash/Pro) |
| Embeddings | google-cloud-aiplatform (VertexAI) |
| Storage | google-cloud-storage |
| Validation | pydantic v2 |
| Deploy | Cloud Run (Dockerfile) |

---

## 3. ARQUITECTURA FLUTTER — CLEAN + FEATURE-FIRST

```
lib/
├── main.dart                     # entrypoint, ProviderScope, runApp
├── app.dart                      # MaterialApp.router, theme, go_router
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart    # BASE_URL, endpoints
│   │   └── app_constants.dart    # timeouts, page sizes
│   ├── errors/
│   │   ├── app_exception.dart    # sealed class AppException
│   │   └── error_handler.dart    # DioException → AppException
│   ├── network/
│   │   ├── dio_client.dart       # Dio factory + interceptors
│   │   ├── auth_interceptor.dart # JWT inject + 401 refresh
│   │   └── connectivity.dart    # offline detection
│   ├── theme/
│   │   ├── app_theme.dart        # Material3 ThemeData light/dark
│   │   ├── app_colors.dart       # navy #0A1628, gold #C9A84C, teal #00D4AA
│   │   └── app_text_styles.dart  # BCG-style typography
│   ├── storage/
│   │   └── secure_storage.dart   # flutter_secure_storage wrapper
│   └── utils/
│       ├── date_utils.dart
│       ├── file_utils.dart
│       └── validators.dart
│
├── shared/
│   ├── widgets/
│   │   ├── app_bar_widget.dart
│   │   ├── loading_overlay.dart
│   │   ├── error_view.dart
│   │   ├── empty_state_view.dart
│   │   ├── status_chip.dart      # PENDIENTE/PROCESANDO/LISTO/ERROR
│   │   ├── kpi_card.dart         # métricas dashboard
│   │   └── document_card.dart    # ítem lista documentos
│   └── providers/
│       └── connectivity_provider.dart
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── user_model.dart         # @freezed
    │   │   │   └── auth_token_model.dart   # @freezed
    │   │   ├── repositories/
    │   │   │   └── auth_repository_impl.dart
    │   │   └── sources/
    │   │       └── auth_remote_source.dart  # @RestApi
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart    # abstract
    │   │   └── usecases/
    │   │       ├── login_usecase.dart
    │   │       ├── logout_usecase.dart
    │   │       └── refresh_token_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── auth_provider.dart      # StateNotifier<AuthState>
    │       └── screens/
    │           ├── splash_screen.dart
    │           ├── login_screen.dart
    │           └── onboarding_screen.dart
    │
    ├── scanner/
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── scan_result_model.dart
    │   │   ├── repositories/
    │   │   │   └── scan_repository_impl.dart
    │   │   └── sources/
    │   │       ├── camera_source.dart       # MLKit DocumentScanner
    │   │       └── upload_remote_source.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── scan_result.dart
    │   │   └── usecases/
    │   │       ├── scan_document_usecase.dart
    │   │       └── upload_document_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── scanner_provider.dart
    │       └── screens/
    │           ├── scanner_screen.dart      # cámara + MLKit
    │           ├── scan_preview_screen.dart # confirmar/descartar páginas
    │           └── upload_progress_screen.dart
    │
    ├── dashboard/
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── document_model.dart
    │   │   │   └── stats_model.dart
    │   │   └── sources/
    │   │       └── dashboard_remote_source.dart
    │   ├── domain/
    │   │   └── usecases/
    │   │       ├── get_stats_usecase.dart
    │   │       └── list_documents_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   ├── stats_provider.dart
    │       │   └── documents_provider.dart  # paginado
    │       └── screens/
    │           ├── dashboard_screen.dart    # home principal
    │           └── document_detail_screen.dart
    │
    ├── hitl/
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── extraction_model.dart
    │   │   │   └── review_model.dart
    │   │   └── sources/
    │   │       └── hitl_remote_source.dart
    │   ├── domain/
    │   │   └── usecases/
    │   │       ├── get_pending_reviews_usecase.dart
    │   │       └── submit_review_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── hitl_provider.dart
    │       └── screens/
    │           ├── hitl_queue_screen.dart   # lista pendientes
    │           └── hitl_review_screen.dart  # split view img+campos
    │
    ├── reports/
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── report_model.dart
    │   │   └── sources/
    │   │       └── reports_remote_source.dart
    │   ├── domain/
    │   │   └── usecases/
    │   │       ├── get_report_data_usecase.dart
    │   │       └── export_report_usecase.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── reports_provider.dart
    │       └── screens/
    │           └── reports_screen.dart
    │
    └── settings/
        └── presentation/
            └── screens/
                └── settings_screen.dart
```

---

## 4. PANTALLAS — INVENTARIO COMPLETO

### Flujo principal
```
Splash → [auth check]
  ├── No auth → Onboarding → Login
  └── Auth OK → Dashboard (home)
                   ├── FAB → Scanner → Preview → Upload → Processing
                   ├── Documento → Detail
                   ├── Nav: HITL Queue → HITL Review
                   ├── Nav: Reports
                   └── Nav: Settings
```

### Especificación pantalla por pantalla

#### SPLASH
- Logo LIFE·IN·CO animado (Lottie)
- Verifica token en secure storage
- Redirige en 1.5s

#### ONBOARDING (3 slides)
- Slide 1: "Digitaliza en segundos" — ícono cámara
- Slide 2: "IA extrae los datos" — ícono robot
- Slide 3: "Revisa y exporta" — ícono check
- Botón "Comenzar" → Login

#### LOGIN
- Logo + tagline
- Campo email (validator)
- Campo password (toggle visibility)
- Botón "Ingresar" → POST /auth/login
- Error inline (credenciales inválidas)
- Loading overlay durante request

#### DASHBOARD (home)
- AppBar: avatar usuario + ícono notificaciones
- Row KPI cards (horizontal scroll):
  - Total procesados (contador animado)
  - Pendientes HITL
  - Tasa de éxito (%)
  - Actas hoy
- Filtro chips: TODO / PENDIENTE / LISTO / ERROR
- ListView paginado de DocumentCard
  - Thumbnail, nombre, fecha, status chip, confianza %
- FAB azul: ícono cámara → Scanner
- Pull-to-refresh
- Bottom nav: Home | HITL | Reports | Settings

#### SCANNER
- Camera preview fullscreen
- MLKit document detection overlay (rectángulo verde)
- Botón capturar (grande, centro inferior)
- Botón galería (izquierda)
- Botón flash (derecha)
- Multi-página: contador "Página 1 / N"
- Botón "Listo" cuando ≥1 página capturada

#### SCAN PREVIEW
- PageView de páginas capturadas (swipe)
- Botón eliminar página
- Botón añadir página → vuelve a cámara
- Nombre del documento (editable)
- Tipo de documento: dropdown [Acta JEP / Formulario / Cédula / Otro]
- Botón "Subir" → comprime + POST multipart

#### UPLOAD PROGRESS
- Progress bar circular
- Estado: "Comprimiendo... / Subiendo... / Procesando con IA..."
- Cancelar (solo durante upload)
- Al completar: "¡Listo! Documento en revisión" + botón "Ver"

#### DOCUMENT DETAIL
- Hero image (thumbnail expandible)
- Metadata: fecha, tipo, lote, operador
- Status timeline: Recibido → OCR → Extracción → HITL → Completado
- Campos extraídos: tabla nombre/valor/confianza
- Botón "Revisar" si status = PENDIENTE_HITL
- Botón "Exportar"

#### HITL QUEUE
- Lista de documentos pendientes de revisión
- Ordenados por prioridad (confianza más baja primero)
- Card: thumbnail + campo con menor confianza + tiempo en cola
- Botón "Revisar" por ítem

#### HITL REVIEW ⭐ (pantalla más compleja)
- Layout split vertical (60/40):
  - TOP: imagen del documento
    - Pinch-to-zoom
    - Highlight del campo activo (rectángulo teal)
    - Botón rotar
  - BOTTOM: campos extraídos
    - Lista scrollable de FieldCard:
      - Nombre del campo (label)
      - Valor extraído (editable inline)
      - Barra de confianza (color: verde/amarillo/rojo)
      - Botón editar
    - Resumen: "12/15 campos verificados"
- AppBar: "1 de 8 pendientes" + flechas siguiente/anterior
- Bottom bar: [Rechazar] [Aprobar] 
  - Rechazar → modal con motivo
  - Aprobar → PATCH /hitl/{id}/review → siguiente

#### REPORTS
- DateRangePicker (últimos 7/30/90 días o custom)
- Selector lote/batch
- Cards de métricas:
  - Documentos procesados
  - Tiempo promedio por documento
  - Accuracy promedio
  - Campos rechazados
- Gráficas (fl_chart):
  - LineChart: tendencia documentos/día
  - BarChart: distribución por tipo
  - PieChart: estado documentos
  - LineChart: accuracy en el tiempo
- Botón "Exportar Excel"
- Botón "Exportar PDF"
- Botón "Compartir"

#### SETTINGS
- Avatar + nombre + email
- Organización
- Notificaciones (toggle)
- Tema (claro/oscuro/sistema)
- Idioma (ES/EN)
- Versión de la app
- Cerrar sesión

---

## 5. NAVEGACIÓN — go_router

```dart
// Rutas
/splash
/onboarding
/login
/home                         → DashboardScreen
/home/document/:id            → DocumentDetailScreen
/scanner                      → ScannerScreen
/scanner/preview              → ScanPreviewScreen
/scanner/uploading            → UploadProgressScreen
/hitl                         → HitlQueueScreen
/hitl/review/:id              → HitlReviewScreen
/reports                      → ReportsScreen
/settings                     → SettingsScreen

// Guard: redirect a /login si no hay token
// Guard: redirect a /home si hay token y va a /login
```

---

## 6. BACKEND — FASTAPI ESTRUCTURA

```
backend/
├── main.py                   # FastAPI app, lifespan, CORS, routers
├── Dockerfile
├── requirements.txt
│
├── core/
│   ├── config.py             # Settings (pydantic BaseSettings)
│   ├── security.py           # JWT create/verify, password hash
│   ├── database.py           # AsyncEngine, SessionLocal, Base
│   └── dependencies.py       # get_db, get_current_user
│
├── models/                   # SQLAlchemy ORM (todos los modelos)
│   ├── user.py
│   ├── organization.py
│   ├── document.py
│   ├── extraction.py
│   ├── hitl_review.py
│   └── audit_log.py
│
├── schemas/                  # Pydantic v2 request/response
│   ├── auth.py
│   ├── document.py
│   ├── extraction.py
│   └── hitl.py
│
├── routers/
│   ├── auth.py               # POST /auth/login, /auth/refresh, /auth/logout
│   ├── documents.py          # GET/POST /documents, GET /documents/{id}
│   ├── ocr.py                # POST /ocr/process (webhook desde upload)
│   ├── hitl.py               # GET /hitl/queue, PATCH /hitl/{id}/review
│   └── reports.py            # GET /reports/stats, /reports/export
│
└── services/
    ├── gemini_service.py      # Gemini 1.5 Flash OCR + extracción
    ├── vertex_service.py      # VertexAI embeddings + búsqueda semántica
    ├── storage_service.py     # Cloud Storage upload/download
    └── export_service.py      # Generar Excel + PDF
```

---

## 7. ALLOYDB — SCHEMA COMPLETO

```sql
-- ORGANIZACIONES
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'starter',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- USUARIOS
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID REFERENCES organizations(id),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'operator',  -- operator | reviewer | admin
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- LOTES DE DOCUMENTOS
CREATE TABLE document_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID REFERENCES organizations(id),
  name TEXT NOT NULL,
  created_by UUID REFERENCES users(id),
  total_docs INTEGER DEFAULT 0,
  processed_docs INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',  -- active | archived
  created_at TIMESTAMPTZ DEFAULT now()
);

-- DOCUMENTOS
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID REFERENCES organizations(id),
  batch_id UUID REFERENCES document_batches(id),
  uploaded_by UUID REFERENCES users(id),
  name TEXT NOT NULL,
  doc_type TEXT,                  -- acta_jep | formulario | cedula | otro
  page_count INTEGER DEFAULT 1,
  storage_path TEXT NOT NULL,     -- Cloud Storage path
  thumbnail_path TEXT,
  status TEXT DEFAULT 'uploaded', -- uploaded|processing|extracted|pending_hitl|completed|error
  ocr_model TEXT,                 -- flash | pro
  ocr_cost_usd DECIMAL(10,6),
  processing_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_documents_org_status ON documents(org_id, status);
CREATE INDEX idx_documents_batch ON documents(batch_id);

-- EXTRACCIONES (campos extraídos por IA)
CREATE TABLE extractions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  field_value TEXT,
  confidence DECIMAL(4,3),        -- 0.000 a 1.000
  bbox JSONB,                     -- {x, y, w, h} en % del original
  extraction_model TEXT,
  is_verified BOOLEAN DEFAULT false,
  verified_value TEXT,            -- valor corregido por humano
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_extractions_doc ON extractions(document_id);

-- REVISIONES HITL
CREATE TABLE hitl_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'pending',  -- pending | approved | rejected
  rejection_reason TEXT,
  fields_corrected INTEGER DEFAULT 0,
  fields_approved INTEGER DEFAULT 0,
  review_ms INTEGER,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- AUDIT LOG
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID REFERENCES organizations(id),
  user_id UUID REFERENCES users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_audit_org_date ON audit_logs(org_id, created_at DESC);

-- EMBEDDINGS (para búsqueda semántica vía VertexAI)
CREATE TABLE document_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  embedding vector(768),          -- AlloyDB pgvector
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_embedding_doc ON document_embeddings(document_id);
```

---

## 8. CONTRATOS API — ENDPOINTS COMPLETOS

### Auth
```
POST /auth/login
  Body: {email, password}
  Response: {access_token, refresh_token, user: {id, name, email, role, org_id}}

POST /auth/refresh
  Body: {refresh_token}
  Response: {access_token, refresh_token}

POST /auth/logout
  Headers: Authorization: Bearer <token>
  Response: {message: "ok"}
```

### Documents
```
GET /documents?status=&batch_id=&page=&limit=20
  Response: {items: [Document], total, page, pages}

POST /documents/upload          (multipart/form-data)
  Fields: files[] (imágenes/pdf), name, doc_type, batch_id?
  Response: {document_id, status: "processing"}

GET /documents/{id}
  Response: Document + extractions[]

GET /documents/stats
  Response: {total, processed, pending_hitl, error, today, accuracy_avg}
```

### HITL
```
GET /hitl/queue?limit=20&offset=0
  Response: {items: [HitlQueueItem], total}
  HitlQueueItem: {document_id, name, thumbnail_url, pending_fields, min_confidence, queue_since}

GET /hitl/{document_id}
  Response: {document, extractions: [{id, field_name, field_value, confidence, bbox, ...}]}

PATCH /hitl/{document_id}/review
  Body: {
    status: "approved"|"rejected",
    rejection_reason?: string,
    corrections?: [{extraction_id, verified_value}]
  }
  Response: {review_id, next_document_id?}
```

### Reports
```
GET /reports/stats?from=&to=&batch_id=
  Response: {
    total_processed, avg_accuracy, avg_processing_ms,
    daily_series: [{date, count, accuracy}],
    by_status: {completed, error, pending},
    by_type: {acta_jep: N, formulario: N, ...}
  }

GET /reports/export?from=&to=&format=xlsx|pdf
  Response: file download (streaming)
```

---

## 9. FLUJO DE DATOS — SCAN → HITL → COMPLETADO

```
1. Usuario abre Scanner → MLKit detecta documento
2. Captura N páginas → comprime (max 1MB/página)
3. POST /documents/upload (multipart)
   → Backend guarda en Cloud Storage
   → Crea documento con status="processing"
   → Lanza task async: OCR pipeline

4. OCR Pipeline (background):
   a. Capa 1: pdfplumber (si PDF nativo) → texto
   b. Capa 2: Gemini Flash → extrae campos + confianza + bbox
   c. Si confianza_promedio < 0.85 → Capa 3: Gemini Pro
   d. Guarda extractions[] en AlloyDB
   e. Genera embedding VertexAI
   f. Status → "pending_hitl" si hay campos < 0.80
               "completed" si todos ≥ 0.80

5. Flutter polling GET /documents/{id} cada 3s hasta status != "processing"

6. Si pending_hitl:
   → Aparece en HitlQueue con prioridad (confianza más baja primero)
   → Reviewer abre HitlReview
   → Corrige campos, aprueba
   → PATCH /hitl/{id}/review
   → Status → "completed"
   → Embedding actualizado con texto corregido

7. Dashboard se actualiza (pull-to-refresh o WebSocket futuro)
```

---

## 10. DESIGN SYSTEM — COLORES Y TIPOGRAFÍA

```dart
// app_colors.dart
static const Color navyDeep   = Color(0xFF0A1628);
static const Color navyLight  = Color(0xFF1A2A45);
static const Color gold       = Color(0xFFC9A84C);
static const Color teal       = Color(0xFF00D4AA);
static const Color cream      = Color(0xFFF5F0E8);
static const Color errorRed   = Color(0xFFE53935);
static const Color warningAmb = Color(0xFFFFA726);
static const Color successGrn = Color(0xFF43A047);

// Confianza → color
// ≥ 0.85 → successGrn
// 0.65-0.84 → warningAmb
// < 0.65 → errorRed
```

---

## 11. VARIABLES DE ENTORNO

### Flutter (.env via flutter_dotenv)
```
API_BASE_URL=https://docintel-api-xxxx-uc.a.run.app
GEMINI_API_KEY=...        # solo para feature flags
ENV=production
```

### Backend (.env)
```
DATABASE_URL=postgresql+asyncpg://user:pass@alloydb-host/docintel
SECRET_KEY=...
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30
GCS_BUCKET_NAME=docintel-documents
GOOGLE_CLOUD_PROJECT=lifeinco-docintel
GEMINI_MODEL_FLASH=gemini-1.5-flash
GEMINI_MODEL_PRO=gemini-1.5-pro
VERTEX_LOCATION=us-central1
EMBEDDING_MODEL=textembedding-gecko@003
```

---

## 12. ESTRUCTURA FINAL DEL REPO GITHUB

```
docintel-agent/
├── index.html              ← landing page (ya en repo)
├── app.html                ← demo interactivo (ya en repo)
├── README.md
│
├── flutter_app/            ← TODO el código Flutter
│   ├── pubspec.yaml
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── test/
│
└── backend/                ← FastAPI
    ├── main.py
    ├── Dockerfile
    ├── requirements.txt
    ├── alembic/
    └── ...
```
