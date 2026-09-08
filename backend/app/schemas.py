from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str
    moh_area: str
    updated_at: datetime

    model_config = {"from_attributes": True}


class PremiseOut(BaseModel):
    id: uuid.UUID
    name: str
    address: str
    owner_name: str
    owner_phone: str | None
    qr_code: str
    latitude: float
    longitude: float
    risk: str
    moh_area: str
    compliance_score: int
    updated_at: datetime

    model_config = {"from_attributes": True}


class ChecklistTemplateOut(BaseModel):
    id: uuid.UUID
    name: str
    updated_at: datetime

    model_config = {"from_attributes": True}


class ChecklistItemOut(BaseModel):
    id: uuid.UUID
    template_id: uuid.UUID
    code: str
    title: str
    description: str
    sort_order: int
    legal_hint: str | None
    updated_at: datetime

    model_config = {"from_attributes": True}


class ScheduledVisitOut(BaseModel):
    id: uuid.UUID
    premise_id: uuid.UUID
    officer_id: uuid.UUID
    visit_date: date
    reason: str
    status: str
    inspection_id: uuid.UUID | None
    notes: str | None
    updated_at: datetime

    model_config = {"from_attributes": True}


class InspectionOut(BaseModel):
    id: uuid.UUID
    premise_id: uuid.UUID
    officer_id: uuid.UUID
    template_id: uuid.UUID
    status: str
    started_at: datetime
    completed_at: datetime | None
    start_lat: float | None
    start_lng: float | None
    submit_lat: float | None
    submit_lng: float | None
    gps_status: str
    follow_up_date: date | None
    notes: str | None
    pdf_path: str | None
    updated_at: datetime

    model_config = {"from_attributes": True}


class InspectionAnswerOut(BaseModel):
    id: uuid.UUID
    inspection_id: uuid.UUID
    item_id: uuid.UUID
    result: str
    notes: str | None
    updated_at: datetime

    model_config = {"from_attributes": True}


class EvidencePhotoOut(BaseModel):
    id: uuid.UUID
    inspection_id: uuid.UUID
    item_id: uuid.UUID | None
    sha256: str
    captured_at: datetime
    latitude: float | None
    longitude: float | None
    storage_path: str
    updated_at: datetime

    model_config = {"from_attributes": True}


class ViolationOut(BaseModel):
    id: uuid.UUID
    inspection_id: uuid.UUID
    item_id: uuid.UUID
    notice_type: str
    legal_provision: str
    deadline: date
    accepted: bool
    updated_at: datetime

    model_config = {"from_attributes": True}


class SignatureOut(BaseModel):
    id: uuid.UUID
    inspection_id: uuid.UUID
    signer_role: str
    signer_name: str
    image_path: str
    image_b64: str | None
    signed_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ComplaintOut(BaseModel):
    id: uuid.UUID
    tracking_no: str
    premise_id: uuid.UUID | None = None
    officer_id: uuid.UUID | None = None
    title: str
    description: str
    priority: str
    status: str
    received_date: date
    updated_at: datetime

    model_config = {"from_attributes": True}


class PullResponse(BaseModel):
    server_time: datetime
    users: list[UserOut]
    premises: list[PremiseOut]
    checklist_templates: list[ChecklistTemplateOut]
    checklist_items: list[ChecklistItemOut]
    scheduled_visits: list[ScheduledVisitOut]
    inspections: list[InspectionOut]
    inspection_answers: list[InspectionAnswerOut]
    evidence_photos: list[EvidencePhotoOut]
    violations: list[ViolationOut]
    signatures: list[SignatureOut]
    complaints: list[ComplaintOut] = []


OpType = Literal[
    "upsert_inspection",
    "upsert_answer",
    "upsert_photo_meta",
    "upsert_violation",
    "upsert_signature",
    "upsert_visit",
    "upsert_premise",
    "upsert_complaint",
]


class SyncOp(BaseModel):
    type: OpType
    payload: dict[str, Any]


class PushRequest(BaseModel):
    ops: list[SyncOp] = Field(default_factory=list)


class PushResponse(BaseModel):
    applied: int
    errors: list[str] = Field(default_factory=list)
