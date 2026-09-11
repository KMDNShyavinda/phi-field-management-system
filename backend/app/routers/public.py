from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import uuid
from pydantic import BaseModel
from typing import Optional, List

from app.database import get_db
from app.models import Complaint, User

router = APIRouter(prefix="/public", tags=["public"])

class PublicComplaintRequest(BaseModel):
    title: str
    description: str
    address: str
    moh_area: str
    isEmergency: bool = False
    reporterName: Optional[str] = None
    reporterPhone: Optional[str] = None

class PublicComplaintResponse(BaseModel):
    id: uuid.UUID
    tracking_no: str
    message: str
    assigned_to: Optional[str] = None

@router.get("/areas", response_model=List[str])
def get_moh_areas(db: Session = Depends(get_db)):
    """Fetch distinct MOH areas that have assigned PHI officers."""
    areas = db.query(User.moh_area).filter(User.role == "phi").distinct().all()
    return sorted([area[0] for area in areas if area[0]])

@router.post("/complaints", response_model=PublicComplaintResponse)
def submit_public_complaint(
    complaint: PublicComplaintRequest,
    db: Session = Depends(get_db)
):
    try:
        new_id = uuid.uuid4()
        tracking_no = f"PUB-{new_id.hex[:6].upper()}"
        
        # Include reporter info in description
        full_desc = complaint.description
        if complaint.reporterName or complaint.reporterPhone:
            reporter = f"\n\n--- Reporter Info ---\nName: {complaint.reporterName or 'N/A'}\nPhone: {complaint.reporterPhone or 'N/A'}"
            full_desc += reporter

        full_desc += f"\n\nLocation: {complaint.address}"

        priority = "emergency" if complaint.isEmergency else "normal"

        # Auto-assign to a PHI in the selected MOH area
        officer = db.query(User).filter(
            User.role == "phi", 
            User.moh_area == complaint.moh_area
        ).first()

        db_complaint = Complaint(
            id=new_id,
            tracking_no=tracking_no,
            title=complaint.title,
            description=full_desc,
            priority=priority,
            status="pending",
            received_date=datetime.utcnow(),
            officer_id=officer.id if officer else None
        )

        db.add(db_complaint)
        db.commit()
        db.refresh(db_complaint)

        assigned_msg = officer.full_name if officer else "Pending Assignment"

        return PublicComplaintResponse(
            id=db_complaint.id,
            tracking_no=db_complaint.tracking_no,
            message="Complaint submitted successfully",
            assigned_to=assigned_msg
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to submit complaint: {str(e)}")
