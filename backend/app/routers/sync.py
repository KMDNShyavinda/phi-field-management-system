from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import (
    ChecklistItem,
    ChecklistTemplate,
    EvidencePhoto,
    Inspection,
    InspectionAnswer,
    Premise,
    ScheduledVisit,
    Signature,
    User,
    Violation,
)
from app.schemas import (
    ChecklistItemOut,
    ChecklistTemplateOut,
    EvidencePhotoOut,
    InspectionAnswerOut,
    InspectionOut,
    PremiseOut,
    PullResponse,
    PushRequest,
    PushResponse,
    ScheduledVisitOut,
    SignatureOut,
    UserOut,
    ViolationOut,
)
from app.sync_apply import apply_op

router = APIRouter(prefix="/sync", tags=["sync"])


def _since_filter(query, model, since: datetime | None):
    if since is None:
        return query
    return query.filter(model.updated_at > since)


@router.get("/pull", response_model=PullResponse)
def pull(
    since: datetime | None = Query(default=None),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> PullResponse:
    premises = _since_filter(db.query(Premise).filter(Premise.moh_area == user.moh_area), Premise, since).all()
    templates = _since_filter(db.query(ChecklistTemplate), ChecklistTemplate, since).all()
    items = _since_filter(db.query(ChecklistItem), ChecklistItem, since).all()
    visits = _since_filter(
        db.query(ScheduledVisit).filter(ScheduledVisit.officer_id == user.id),
        ScheduledVisit,
        since,
    ).all()
    inspections = _since_filter(
        db.query(Inspection).filter(Inspection.officer_id == user.id),
        Inspection,
        since,
    ).all()
    inspection_ids = [row.id for row in db.query(Inspection.id).filter(Inspection.officer_id == user.id).all()]

    answers = []
    photos = []
    violations = []
    signatures = []
    if inspection_ids:
        answers = _since_filter(
            db.query(InspectionAnswer).filter(InspectionAnswer.inspection_id.in_(inspection_ids)),
            InspectionAnswer,
            since,
        ).all()
        photos = _since_filter(
            db.query(EvidencePhoto).filter(EvidencePhoto.inspection_id.in_(inspection_ids)),
            EvidencePhoto,
            since,
        ).all()
        violations = _since_filter(
            db.query(Violation).filter(Violation.inspection_id.in_(inspection_ids)),
            Violation,
            since,
        ).all()
        signatures = _since_filter(
            db.query(Signature).filter(Signature.inspection_id.in_(inspection_ids)),
            Signature,
            since,
        ).all()

    return PullResponse(
        server_time=datetime.utcnow(),
        users=[UserOut.model_validate(user)],
        premises=[PremiseOut.model_validate(row) for row in premises],
        checklist_templates=[ChecklistTemplateOut.model_validate(row) for row in templates],
        checklist_items=[ChecklistItemOut.model_validate(row) for row in items],
        scheduled_visits=[ScheduledVisitOut.model_validate(row) for row in visits],
        inspections=[InspectionOut.model_validate(row) for row in inspections],
        inspection_answers=[InspectionAnswerOut.model_validate(row) for row in answers],
        evidence_photos=[EvidencePhotoOut.model_validate(row) for row in photos],
        violations=[ViolationOut.model_validate(row) for row in violations],
        signatures=[SignatureOut.model_validate(row) for row in signatures],
    )


@router.post("/push", response_model=PushResponse)
def push(
    body: PushRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> PushResponse:
    applied = 0
    errors: list[str] = []
    for op in body.ops:
        try:
            apply_op(db, user, op.type, op.payload)
            db.commit()
            applied += 1
        except Exception as exc:  # noqa: BLE001 — isolate a single bad op
            db.rollback()
            errors.append(f"{op.type}: {exc}")
    return PushResponse(applied=applied, errors=errors)
