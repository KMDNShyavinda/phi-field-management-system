import uuid
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import Premise, Inspection, Violation, Complaint, InspectionAnswer

def calculate_premise_risk(db: Session, premise_id: uuid.UUID) -> None:
    """
    Calculates the compliance score and risk level for a premise based on:
    - Recent violations (Critical = -20, High = -15, Medium = -10, Low = -5)
    - Failed inspection answers (-2 per failure)
    - Active complaints (-5 per active, -10 if emergency)
    Base score is 100. Minimum score is 0.
    """
    premise = db.get(Premise, premise_id)
    if not premise:
        return

    score = 100

    # 1. Deduct for recent violations
    # Fetch all violations for this premise through inspections
    violations = db.query(Violation).join(Inspection).filter(
        Inspection.premise_id == premise_id,
        Violation.accepted == True
    ).all()

    for v in violations:
        notice = v.notice_type.lower()
        if 'critical' in notice or 'closure' in notice:
            score -= 20
        elif 'high' in notice or 'fine' in notice:
            score -= 15
        elif 'medium' in notice or 'improvement' in notice:
            score -= 10
        else:
            score -= 5

    # 2. Deduct for failed items in the latest inspection
    latest_inspection = db.query(Inspection).filter(
        Inspection.premise_id == premise_id,
        Inspection.status == 'completed'
    ).order_by(Inspection.completed_at.desc()).first()

    if latest_inspection:
        failed_count = db.query(InspectionAnswer).filter(
            InspectionAnswer.inspection_id == latest_inspection.id,
            InspectionAnswer.result == 'fail'
        ).count()
        score -= (failed_count * 2)

    # 3. Deduct for active complaints
    active_complaints = db.query(Complaint).filter(
        Complaint.premise_id == premise_id,
        Complaint.status.in_(['pending', 'investigating'])
    ).all()

    for c in active_complaints:
        if c.priority.lower() == 'emergency':
            score -= 10
        elif c.priority.lower() == 'high':
            score -= 8
        else:
            score -= 5

    # Ensure score is within 0-100 bounds
    score = max(0, min(100, score))
    premise.compliance_score = score

    # Determine risk label
    if score >= 85:
        premise.risk = "low"
    elif score >= 65:
        premise.risk = "medium"
    elif score >= 40:
        premise.risk = "high"
    else:
        premise.risk = "critical"

    db.add(premise)
    # The caller is expected to commit
