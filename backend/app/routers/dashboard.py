from datetime import date, datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.auth import get_current_user
from app.models import User, Inspection, Premise, ScheduledVisit, Violation

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

@router.get("/stats")
def get_dashboard_stats(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns statistics for the dashboard.
    If the user is a PHI Officer, it filters by their assigned area and their inspections.
    """
    today = date.today()
    
    # 1. Today's Inspections (Completed and Draft)
    today_inspections = db.query(Inspection).filter(
        Inspection.officer_id == current_user.id,
        func.date(Inspection.started_at) == today
    ).count()

    # 2. Pending Follow-ups (Scheduled visits with reason='follow_up' that are pending)
    pending_followups = db.query(ScheduledVisit).filter(
        ScheduledVisit.officer_id == current_user.id,
        ScheduledVisit.reason == "follow_up",
        ScheduledVisit.status == "pending"
    ).count()

    # 3. High Risk Places in their MOH area
    high_risk_places = db.query(Premise).filter(
        Premise.moh_area == current_user.moh_area,
        Premise.risk.in_(["high", "critical"])
    ).count()

    # 4. Total Violations recorded by this officer this month
    current_month = today.replace(day=1)
    monthly_violations = db.query(Violation).join(Inspection).filter(
        Inspection.officer_id == current_user.id,
        Violation.updated_at >= current_month
    ).count()

    return {
        "today_inspections": today_inspections,
        "pending_followups": pending_followups,
        "high_risk_places": high_risk_places,
        "monthly_violations": monthly_violations,
        "moh_area": current_user.moh_area
    }

@router.get("/admin_stats")
def get_admin_dashboard_stats(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns aggregate statistics for the Admin/MOH Dashboard.
    """
    from app.models import Complaint
    today = date.today()
    current_month = today.replace(day=1)
    
    # 1. Total Inspections this month (Global or MOH specific)
    total_inspections = db.query(Inspection).filter(
        Inspection.started_at >= current_month
    ).count()

    # 2. Active Complaints
    active_complaints_query = db.query(Complaint).filter(
        Complaint.status.in_(["pending", "investigating"])
    )
    active_complaints = active_complaints_query.count()
    emergency_complaints = active_complaints_query.filter(Complaint.priority.in_(["emergency", "critical"])).count()

    # 3. Violations Issued (Requires follow up - simply unaccepted or open, here we just count month)
    violations_issued = db.query(Violation).filter(
        Violation.updated_at >= current_month
    ).count()

    # 4. Total PHI Officers
    total_officers = db.query(User).filter(User.role == "phi").count()

    return {
        "total_inspections_month": total_inspections,
        "active_complaints": active_complaints,
        "emergency_complaints": emergency_complaints,
        "violations_issued": violations_issued,
        "total_officers": total_officers,
        "moh_area": current_user.moh_area
    }

@router.get("/complaints")
def get_all_complaints(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns all complaints for the admin dashboard.
    """
    from app.models import Complaint
    # Ideally filter by MOH area if current_user is just MOH, but for MVP returning all or area specific
    complaints = db.query(Complaint).order_by(Complaint.received_date.desc()).all()
    
    result = []
    for c in complaints:
        result.append({
            "id": c.id,
            "tracking_no": c.tracking_no,
            "title": c.title,
            "description": c.description,
            "priority": c.priority,
            "status": c.status,
            "received_date": c.received_date,
            "updated_at": c.updated_at
        })
    return result

@router.get("/officers")
def get_all_officers(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns all PHI officers.
    """
    officers = db.query(User).filter(User.role == "phi").all()
    
    result = []
    for o in officers:
        result.append({
            "id": o.id,
            "full_name": o.full_name,
            "email": o.email,
            "moh_area": o.moh_area,
            "is_active": o.is_active
        })
    return result

@router.get("/inspections")
def get_all_inspections(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns all inspections.
    """
    inspections = db.query(Inspection).order_by(Inspection.started_at.desc()).all()
    
    result = []
    for i in inspections:
        premise = db.query(Premise).filter(Premise.id == i.premise_id).first()
        officer = db.query(User).filter(User.id == i.officer_id).first()
        result.append({
            "id": i.id,
            "premise_name": premise.name if premise else "Unknown",
            "officer_name": officer.full_name if officer else "Unknown",
            "started_at": i.started_at,
            "ended_at": i.ended_at,
            "compliance_score": i.compliance_score
        })
    return result
