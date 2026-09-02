from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def utcnow() -> datetime:
    return datetime.utcnow()


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(32), default="phi")
    moh_area: Mapped[str] = mapped_column(String(128))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspections: Mapped[list[Inspection]] = relationship(back_populates="officer")


class Premise(Base):
    __tablename__ = "premises"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255))
    address: Mapped[str] = mapped_column(String(512))
    owner_name: Mapped[str] = mapped_column(String(255))
    owner_phone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    qr_code: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    risk: Mapped[str] = mapped_column(String(32), default="medium")
    moh_area: Mapped[str] = mapped_column(String(128), index=True)
    compliance_score: Mapped[int] = mapped_column(Integer, default=70)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspections: Mapped[list[Inspection]] = relationship(back_populates="premise")
    visits: Mapped[list[ScheduledVisit]] = relationship(back_populates="premise")


class ChecklistTemplate(Base):
    __tablename__ = "checklist_templates"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    items: Mapped[list[ChecklistItem]] = relationship(back_populates="template")


class ChecklistItem(Base):
    __tablename__ = "checklist_items"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    template_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("checklist_templates.id"), index=True)
    code: Mapped[str] = mapped_column(String(64), index=True)
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text, default="")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    legal_hint: Mapped[str | None] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    template: Mapped[ChecklistTemplate] = relationship(back_populates="items")


class ScheduledVisit(Base):
    __tablename__ = "scheduled_visits"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    premise_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("premises.id"), index=True)
    officer_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id"), index=True)
    visit_date: Mapped[date] = mapped_column(Date, index=True)
    reason: Mapped[str] = mapped_column(String(64), default="planned")
    status: Mapped[str] = mapped_column(String(32), default="pending")
    inspection_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    premise: Mapped[Premise] = relationship(back_populates="visits")


class Inspection(Base):
    __tablename__ = "inspections"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    premise_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("premises.id"), index=True)
    officer_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("users.id"), index=True)
    template_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("checklist_templates.id"))
    status: Mapped[str] = mapped_column(String(32), default="draft")
    started_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    start_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    start_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    submit_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    submit_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    gps_status: Mapped[str] = mapped_column(String(32), default="unavailable")
    follow_up_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    pdf_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    premise: Mapped[Premise] = relationship(back_populates="inspections")
    officer: Mapped[User] = relationship(back_populates="inspections")
    answers: Mapped[list[InspectionAnswer]] = relationship(back_populates="inspection")
    photos: Mapped[list[EvidencePhoto]] = relationship(back_populates="inspection")
    violations: Mapped[list[Violation]] = relationship(back_populates="inspection")
    signatures: Mapped[list[Signature]] = relationship(back_populates="inspection")


class InspectionAnswer(Base):
    __tablename__ = "inspection_answers"
    __table_args__ = (UniqueConstraint("inspection_id", "item_id", name="uq_answer_item"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    inspection_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("inspections.id"), index=True)
    item_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("checklist_items.id"), index=True)
    result: Mapped[str] = mapped_column(String(16))
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspection: Mapped[Inspection] = relationship(back_populates="answers")


class EvidencePhoto(Base):
    __tablename__ = "evidence_photos"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    inspection_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("inspections.id"), index=True)
    item_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, ForeignKey("checklist_items.id"), nullable=True)
    sha256: Mapped[str] = mapped_column(String(64))
    captured_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    storage_path: Mapped[str] = mapped_column(String(512), default="")
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspection: Mapped[Inspection] = relationship(back_populates="photos")


class Violation(Base):
    __tablename__ = "violations"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    inspection_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("inspections.id"), index=True)
    item_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("checklist_items.id"))
    notice_type: Mapped[str] = mapped_column(String(64))
    legal_provision: Mapped[str] = mapped_column(Text)
    deadline: Mapped[date] = mapped_column(Date)
    accepted: Mapped[bool] = mapped_column(default=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspection: Mapped[Inspection] = relationship(back_populates="violations")


class Signature(Base):
    __tablename__ = "signatures"
    __table_args__ = (UniqueConstraint("inspection_id", "signer_role", name="uq_signature_role"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    inspection_id: Mapped[uuid.UUID] = mapped_column(Uuid, ForeignKey("inspections.id"), index=True)
    signer_role: Mapped[str] = mapped_column(String(32))
    signer_name: Mapped[str] = mapped_column(String(255))
    image_path: Mapped[str] = mapped_column(String(512), default="")
    image_b64: Mapped[str | None] = mapped_column(Text, nullable=True)
    signed_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    inspection: Mapped[Inspection] = relationship(back_populates="signatures")
