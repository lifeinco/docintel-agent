"""document_batches + documents tables (ARCHITECTURE.md §7).

Document.status lifecycle:
uploaded → processing → extracted → pending_hitl → completed | error
"""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Index, Integer, Numeric, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from core.database import Base


class DocumentBatch(Base):
    __tablename__ = "document_batches"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    org_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("organizations.id")
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id")
    )
    total_docs: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    processed_docs: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    status: Mapped[str] = mapped_column(
        Text, nullable=False, server_default=text("'active'")
    )  # active | archived
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    documents: Mapped[list["Document"]] = relationship(back_populates="batch")


class Document(Base):
    __tablename__ = "documents"
    __table_args__ = (
        Index("idx_documents_org_status", "org_id", "status"),
        Index("idx_documents_batch", "batch_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    org_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("organizations.id")
    )
    batch_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("document_batches.id")
    )
    uploaded_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id")
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    doc_type: Mapped[str | None] = mapped_column(
        Text
    )  # acta_jep | formulario | cedula | otro
    page_count: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("1")
    )
    storage_path: Mapped[str] = mapped_column(Text, nullable=False)
    thumbnail_path: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(
        Text, nullable=False, server_default=text("'uploaded'")
    )
    ocr_model: Mapped[str | None] = mapped_column(Text)  # flash | pro
    ocr_cost_usd: Mapped[Decimal | None] = mapped_column(Numeric(10, 6))
    processing_ms: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    batch: Mapped["DocumentBatch | None"] = relationship(
        back_populates="documents"
    )
    extractions: Mapped[list["Extraction"]] = relationship(  # noqa: F821
        back_populates="document",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    reviews: Mapped[list["HitlReview"]] = relationship(  # noqa: F821
        back_populates="document",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
