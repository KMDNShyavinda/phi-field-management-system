from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import uuid
from pydantic import BaseModel
from typing import Optional

from app.database import get_db
from app.models import Complaint

router = APIRouter(prefix="/public", tags=["public"])

class PublicComplaintRequest(BaseModel):
    title: str
    description: str
    address: str
    isEmergency: bool = False
    reporterName: Optional[str] = None
    reporterPhone: Optional[str] = None

class PublicComplaintResponse(BaseModel):
    id: uuid.UUID
    tracking_no: str
    message: str

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

        db_complaint = Complaint(
            id=new_id,
            tracking_no=tracking_no,
            title=complaint.title,
            description=full_desc,
            priority=priority,
            status="pending",
            received_date=datetime.utcnow()
        )

        db.add(db_complaint)
        db.commit()
        db.refresh(db_complaint)

        return PublicComplaintResponse(
            id=db_complaint.id,
            tracking_no=db_complaint.tracking_no,
            message="Complaint submitted successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to submit complaint: {str(e)}")
