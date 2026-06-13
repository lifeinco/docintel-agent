"""Document endpoints: list, upload (+ background OCR), stats, detail."""
import asyncio
import logging
import math
import os
import tempfile
import time
import uuid
from datetime import datetime, time as dt_time, timezone
from decimal import Decimal

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

import aiofiles

from core.config import settings
from core.database import AsyncSessionLocal, get_db
from core.dependencies import get_current_user
from models.document import Document, DocumentBatch
from models.extraction import Extraction
from models.user import User
from schemas.document import (
    DocumentListResponse,
    DocumentResponse,
    StatsResponse,
    UploadResponse,
)
from services.gemini_service import gemini_service
from services.storage_service import storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/documents", tags=["documents"])

# Fields below this confidence force the document into the HITL queue.
HITL_CONFIDENCE_THRESHOLD = 0.80

# Rough per-page costs used for the ocr_cost_usd estimate.
_COST_PER_PAGE = {"flash": Decimal("0.0002"), "pro": Decimal("0.0035")}

_ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "application/pdf",
}


# ---------------------------------------------------------------------------
# Background OCR pipeline (ARCHITECTURE.md §9, step 4)
# ---------------------------------------------------------------------------
async def _process_document_ocr(
    document_id: uuid.UUID,
    local_paths: list[str],
    doc_type: str,
) -> None:
    """Runs the Gemini extraction cascade and persists the results.

    Executes outside the request lifecycle (asyncio.create_task), so it
    opens its own DB session and never raises to the caller.
    """
    started = time.monotonic()
    try:
        fields = await gemini_service.extract_fields(local_paths, doc_type)
        avg_confidence = gemini_service.average_confidence(fields)
        used_pro = any(
            f.get("extraction_model") == settings.gemini_model_pro
            for f in fields
        )
        has_low_confidence = any(
            (f.get("confidence") or 0.0) < HITL_CONFIDENCE_THRESHOLD
            for f in fields
        )
        new_status = (
            "pending_hitl" if (has_low_confidence or not fields) else "completed"
        )
        elapsed_ms = int((time.monotonic() - started) * 1000)

        async with AsyncSessionLocal() as session:
            document = await session.get(Document, document_id)
            if document is None:
                logger.error("OCR: documento %s desapareció", document_id)
                return

            for field in fields:
                session.add(
                    Extraction(
                        document_id=document_id,
                        field_name=field["field_name"],
                        field_value=field.get("field_value"),
                        confidence=Decimal(str(round(field["confidence"], 3))),
                        bbox=field.get("bbox"),
                        extraction_model=field.get("extraction_model"),
                    )
                )

            model_label = "pro" if used_pro else "flash"
            document.status = new_status
            document.ocr_model = model_label
            document.processing_ms = elapsed_ms
            document.ocr_cost_usd = (
                _COST_PER_PAGE[model_label] * document.page_count
            )

            if document.batch_id is not None:
                batch = await session.get(DocumentBatch, document.batch_id)
                if batch is not None:
                    batch.processed_docs = (batch.processed_docs or 0) + 1

            await session.commit()
            logger.info(
                "OCR %s: %d campos, avg=%.3f, modelo=%s, status=%s (%d ms)",
                document_id,
                len(fields),
                avg_confidence,
                model_label,
                new_status,
                elapsed_ms,
            )
    except asyncio.CancelledError:
        raise
    except Exception:
        logger.exception("OCR pipeline falló para %s", document_id)
        try:
            async with AsyncSessionLocal() as session:
                document = await session.get(Document, document_id)
                if document is not None:
                    document.status = "error"
                    await session.commit()
        except Exception:
            logger.exception("No se pudo marcar error en %s", document_id)
    finally:
        for path in local_paths:
            try:
                os.remove(path)
            except OSError:
                pass


# ---------------------------------------------------------------------------
# Endpoints — NOTE: /stats must be declared before /{document_id}
# ---------------------------------------------------------------------------
@router.get("", response_model=DocumentListResponse)
async def list_documents(
    status_filter: str | None = Query(None, alias="status"),
    batch_id: uuid.UUID | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DocumentListResponse:
    """Paginated, org-scoped document list with status/batch filters."""
    conditions = [Document.org_id == current_user.org_id]
    if status_filter:
        conditions.append(Document.status == status_filter)
    if batch_id:
        conditions.append(Document.batch_id == batch_id)

    total = (
        await db.execute(
            select(func.count()).select_from(Document).where(*conditions)
        )
    ).scalar_one()

    result = await db.execute(
        select(Document)
        .where(*conditions)
        .order_by(Document.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
    )
    items = result.scalars().all()

    return DocumentListResponse(
        items=[DocumentResponse.model_validate(d) for d in items],
        total=total,
        page=page,
        pages=max(1, math.ceil(total / limit)),
    )


@router.post(
    "/upload",
    response_model=UploadResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def upload_document(
    files: list[UploadFile] = File(...),
    name: str = Form(...),
    doc_type: str = Form("otro"),
    batch_id: uuid.UUID | None = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UploadResponse:
    """Stores the pages in GCS, creates the Document record and launches the
    OCR pipeline as a fire-and-forget background task."""
    if not files:
        raise HTTPException(422, "Debe adjuntar al menos una página")

    document_id = uuid.uuid4()
    gcs_paths: list[str] = []
    local_paths: list[str] = []
    tmp_dir = tempfile.gettempdir()

    try:
        for index, upload in enumerate(files, start=1):
            content_type = upload.content_type or "image/jpeg"
            if content_type not in _ALLOWED_CONTENT_TYPES:
                raise HTTPException(
                    422, f"Tipo de archivo no soportado: {content_type}"
                )
            data = await upload.read()
            if not data:
                raise HTTPException(422, f"La página {index} está vacía")

            ext = os.path.splitext(upload.filename or "")[1] or ".jpg"
            gcs_path = (
                f"orgs/{current_user.org_id}/documents/{document_id}"
                f"/page_{index:03d}{ext}"
            )
            await storage_service.upload_file(
                data, gcs_path, content_type=content_type
            )
            gcs_paths.append(gcs_path)

            # Local copy for the Gemini pass (deleted by the pipeline).
            local_path = os.path.join(
                tmp_dir, f"docintel_{document_id}_p{index:03d}{ext}"
            )
            async with aiofiles.open(local_path, "wb") as handle:
                await handle.write(data)
            local_paths.append(local_path)
    except HTTPException:
        for path in local_paths:
            try:
                os.remove(path)
            except OSError:
                pass
        raise

    document = Document(
        id=document_id,
        org_id=current_user.org_id,
        batch_id=batch_id,
        uploaded_by=current_user.id,
        name=name,
        doc_type=doc_type,
        page_count=len(files),
        storage_path=f"orgs/{current_user.org_id}/documents/{document_id}/",
        thumbnail_path=gcs_paths[0],
        status="processing",
    )
    db.add(document)

    if batch_id is not None:
        batch = await db.get(DocumentBatch, batch_id)
        if batch is not None:
            batch.total_docs = (batch.total_docs or 0) + 1

    await db.commit()

    asyncio.create_task(
        _process_document_ocr(document_id, local_paths, doc_type)
    )

    return UploadResponse(document_id=str(document_id), status="processing")


@router.get("/stats", response_model=StatsResponse)
async def get_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> StatsResponse:
    """Aggregate KPIs for the dashboard (ARCHITECTURE.md §8)."""
    org_filter = Document.org_id == current_user.org_id

    by_status_rows = (
        await db.execute(
            select(Document.status, func.count(Document.id))
            .where(org_filter)
            .group_by(Document.status)
        )
    ).all()
    by_status = {row[0]: row[1] for row in by_status_rows}
    total = sum(by_status.values())

    today_start = datetime.combine(
        datetime.now(timezone.utc).date(), dt_time.min, tzinfo=timezone.utc
    )
    today = (
        await db.execute(
            select(func.count(Document.id)).where(
                org_filter, Document.created_at >= today_start
            )
        )
    ).scalar_one()

    accuracy_avg = (
        await db.execute(
            select(func.avg(Extraction.confidence))
            .join(Document, Document.id == Extraction.document_id)
            .where(org_filter)
        )
    ).scalar_one()

    return StatsResponse(
        total=total,
        processed=by_status.get("completed", 0),
        pending_hitl=by_status.get("pending_hitl", 0),
        error_count=by_status.get("error", 0),
        today=today,
        accuracy_avg=float(accuracy_avg) if accuracy_avg is not None else 0.0,
    )


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DocumentResponse:
    document = await db.get(Document, document_id)
    if document is None or document.org_id != current_user.org_id:
        raise HTTPException(404, "Documento no encontrado")
    return DocumentResponse.model_validate(document)
