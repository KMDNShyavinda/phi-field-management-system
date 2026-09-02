from pathlib import Path
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.config import get_settings
from app.database import get_db
from app.models import EvidencePhoto, Inspection, User, utcnow

router = APIRouter(prefix="/media", tags=["media"])
settings = get_settings()


def _media_root() -> Path:
    path = Path(settings.media_root)
    path.mkdir(parents=True, exist_ok=True)
    (path / "photos").mkdir(parents=True, exist_ok=True)
    (path / "reports").mkdir(parents=True, exist_ok=True)
    return path


@router.post("/photos")
async def upload_photo(
    photo_id: UUID = Form(...),
    inspection_id: UUID = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    inspection = db.get(Inspection, inspection_id)
    if inspection is None or inspection.officer_id != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")
    photo = db.get(EvidencePhoto, photo_id)
    if photo is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo metadata not synced yet")
    suffix = Path(file.filename or "evidence.jpg").suffix or ".jpg"
    dest = _media_root() / "photos" / f"{photo_id}{suffix}"
    dest.write_bytes(await file.read())
    photo.storage_path = str(dest)
    photo.updated_at = utcnow()
    db.commit()
    return {"id": str(photo_id), "storage_path": photo.storage_path}


@router.post("/reports")
async def upload_report(
    inspection_id: UUID = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    inspection = db.get(Inspection, inspection_id)
    if inspection is None or inspection.officer_id != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")
    dest = _media_root() / "reports" / f"{inspection_id}.pdf"
    dest.write_bytes(await file.read())
    inspection.pdf_path = str(dest)
    inspection.updated_at = utcnow()
    db.commit()
    return {"inspection_id": str(inspection_id), "storage_path": str(dest)}


@router.get("/photos/{photo_id}")
def download_photo(
    photo_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> FileResponse:
    photo = db.get(EvidencePhoto, photo_id)
    if photo is None or not photo.storage_path:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")
    inspection = db.get(Inspection, photo.inspection_id)
    if inspection is None or inspection.officer_id != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")
    path = Path(photo.storage_path)
    if not path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File missing")
    return FileResponse(path)


@router.get("/reports/{inspection_id}")
def download_report(
    inspection_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> FileResponse:
    inspection = db.get(Inspection, inspection_id)
    if inspection is None or inspection.officer_id != user.id or not inspection.pdf_path:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    path = Path(inspection.pdf_path)
    if not path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File missing")
    return FileResponse(path, media_type="application/pdf", filename=f"inspection-{inspection_id}.pdf")
