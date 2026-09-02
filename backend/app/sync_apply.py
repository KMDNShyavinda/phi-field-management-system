from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.models import (
    EvidencePhoto,
    Inspection,
    InspectionAnswer,
    ScheduledVisit,
    Signature,
    User,
    Violation,
    utcnow,
)


def _parse_uuid(value: str | UUID) -> UUID:
    return value if isinstance(value, UUID) else UUID(str(value))


def _parse_dt(value: str | datetime | None) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.replace(tzinfo=None)
    text = str(value).replace("Z", "+00:00")
    parsed = datetime.fromisoformat(text)
    return parsed.replace(tzinfo=None)


def _parse_date(value: str | date | None) -> date | None:
    if value is None:
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    return date.fromisoformat(str(value)[:10])


def _newer(incoming: datetime | None, existing: datetime | None) -> bool:
    if incoming is None or existing is None:
        return True
    return incoming >= existing


def _set_if_newer(row, payload: dict, fields: dict) -> None:
    incoming = _parse_dt(payload.get("updated_at"))
    if not _newer(incoming, getattr(row, "updated_at", None)):
        return
    for key, value in fields.items():
        setattr(row, key, value)
    row.updated_at = incoming or utcnow()


def apply_op(db: Session, user: User, op_type: str, payload: dict) -> None:
    if op_type == "upsert_inspection":
        _upsert_inspection(db, user, payload)
    elif op_type == "upsert_answer":
        _upsert_answer(db, user, payload)
    elif op_type == "upsert_photo_meta":
        _upsert_photo(db, user, payload)
    elif op_type == "upsert_violation":
        _upsert_violation(db, user, payload)
    elif op_type == "upsert_signature":
        _upsert_signature(db, user, payload)
    elif op_type == "upsert_visit":
        _upsert_visit(db, user, payload)
    else:
        raise ValueError(f"Unknown op {op_type}")


def _require_own_inspection(db: Session, user: User, inspection_id: UUID) -> Inspection:
    inspection = db.get(Inspection, inspection_id)
    if inspection is None:
        raise ValueError("Inspection not found")
    if inspection.officer_id != user.id:
        raise ValueError("Inspection does not belong to this officer")
    return inspection


def _upsert_inspection(db: Session, user: User, payload: dict) -> None:
    inspection_id = _parse_uuid(payload["id"])
    row = db.get(Inspection, inspection_id)
    fields = {
        "premise_id": _parse_uuid(payload["premise_id"]),
        "officer_id": user.id,
        "template_id": _parse_uuid(payload["template_id"]),
        "status": payload.get("status", "draft"),
        "started_at": _parse_dt(payload.get("started_at")) or utcnow(),
        "completed_at": _parse_dt(payload.get("completed_at")),
        "start_lat": payload.get("start_lat"),
        "start_lng": payload.get("start_lng"),
        "submit_lat": payload.get("submit_lat"),
        "submit_lng": payload.get("submit_lng"),
        "gps_status": payload.get("gps_status", "unavailable"),
        "follow_up_date": _parse_date(payload.get("follow_up_date")),
        "notes": payload.get("notes"),
        "pdf_path": payload.get("pdf_path"),
    }
    if row is None:
        row = Inspection(id=inspection_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow())
        db.add(row)
        return
    if row.officer_id != user.id:
        raise ValueError("Cannot overwrite another officer's inspection")
    _set_if_newer(row, payload, fields)


def _upsert_answer(db: Session, user: User, payload: dict) -> None:
    row_id = _parse_uuid(payload["id"])
    inspection_id = _parse_uuid(payload["inspection_id"])
    _require_own_inspection(db, user, inspection_id)
    fields = {
        "inspection_id": inspection_id,
        "item_id": _parse_uuid(payload["item_id"]),
        "result": payload["result"],
        "notes": payload.get("notes"),
    }
    row = db.get(InspectionAnswer, row_id)
    if row is None:
        db.add(InspectionAnswer(id=row_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow()))
        return
    _set_if_newer(row, payload, fields)


def _upsert_photo(db: Session, user: User, payload: dict) -> None:
    row_id = _parse_uuid(payload["id"])
    inspection_id = _parse_uuid(payload["inspection_id"])
    _require_own_inspection(db, user, inspection_id)
    existing = db.get(EvidencePhoto, row_id)
    fields = {
        "inspection_id": inspection_id,
        "item_id": _parse_uuid(payload["item_id"]) if payload.get("item_id") else None,
        "sha256": payload.get("sha256", ""),
        "captured_at": _parse_dt(payload.get("captured_at")) or utcnow(),
        "latitude": payload.get("latitude"),
        "longitude": payload.get("longitude"),
        "storage_path": payload.get("storage_path", existing.storage_path if existing else ""),
    }
    if existing is None:
        db.add(EvidencePhoto(id=row_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow()))
        return
    _set_if_newer(existing, payload, fields)


def _upsert_violation(db: Session, user: User, payload: dict) -> None:
    row_id = _parse_uuid(payload["id"])
    inspection_id = _parse_uuid(payload["inspection_id"])
    _require_own_inspection(db, user, inspection_id)
    fields = {
        "inspection_id": inspection_id,
        "item_id": _parse_uuid(payload["item_id"]),
        "notice_type": payload.get("notice_type", "improvement_notice"),
        "legal_provision": payload.get("legal_provision", ""),
        "deadline": _parse_date(payload["deadline"]),
        "accepted": bool(payload.get("accepted", True)),
    }
    row = db.get(Violation, row_id)
    if row is None:
        db.add(Violation(id=row_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow()))
        return
    _set_if_newer(row, payload, fields)


def _upsert_signature(db: Session, user: User, payload: dict) -> None:
    row_id = _parse_uuid(payload["id"])
    inspection_id = _parse_uuid(payload["inspection_id"])
    _require_own_inspection(db, user, inspection_id)
    fields = {
        "inspection_id": inspection_id,
        "signer_role": payload["signer_role"],
        "signer_name": payload.get("signer_name", ""),
        "image_path": payload.get("image_path", ""),
        "image_b64": payload.get("image_b64"),
        "signed_at": _parse_dt(payload.get("signed_at")) or utcnow(),
    }
    row = db.get(Signature, row_id)
    if row is None:
        db.add(Signature(id=row_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow()))
        return
    _set_if_newer(row, payload, fields)


def _upsert_visit(db: Session, user: User, payload: dict) -> None:
    row_id = _parse_uuid(payload["id"])
    fields = {
        "premise_id": _parse_uuid(payload["premise_id"]),
        "officer_id": user.id,
        "visit_date": _parse_date(payload["visit_date"]),
        "reason": payload.get("reason", "planned"),
        "status": payload.get("status", "pending"),
        "inspection_id": _parse_uuid(payload["inspection_id"]) if payload.get("inspection_id") else None,
        "notes": payload.get("notes"),
    }
    row = db.get(ScheduledVisit, row_id)
    if row is None:
        db.add(ScheduledVisit(id=row_id, **fields, updated_at=_parse_dt(payload.get("updated_at")) or utcnow()))
        return
    if row.officer_id != user.id:
        raise ValueError("Cannot overwrite another officer's visit")
    _set_if_newer(row, payload, fields)
