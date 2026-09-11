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
