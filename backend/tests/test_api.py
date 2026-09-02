from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta
from io import BytesIO

from app.models import Inspection
from app.seed import PHI_ID, TEMPLATE_ID, PREMISES


def _auth(client) -> dict[str, str]:
    response = client.post("/auth/login", json={"email": "phi@moh.lk", "password": "phi12345"})
    assert response.status_code == 200, response.text
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_health(client) -> None:
    assert client.get("/health").json() == {"status": "ok"}


def test_login_rejects_bad_password(client) -> None:
    response = client.post("/auth/login", json={"email": "phi@moh.lk", "password": "wrong"})
    assert response.status_code == 401


def test_pull_seed_data(client) -> None:
    headers = _auth(client)
    pulled = client.get("/sync/pull", headers=headers).json()
    assert len(pulled["premises"]) == 6
    assert len(pulled["checklist_items"]) == 8
    assert len(pulled["scheduled_visits"]) >= 4
    assert pulled["premises"][0]["qr_code"].startswith("phi://premise/")


def test_push_inspection_is_idempotent(client, db) -> None:
    headers = _auth(client)
    inspection_id = str(uuid.uuid4())
    premise_id = str(PREMISES[0]["id"])
    now = datetime.utcnow().isoformat()
    item_id = "00000000-0000-4000-8000-000000000201"
    answer_id = str(uuid.uuid4())
    photo_id = str(uuid.uuid4())
    violation_id = str(uuid.uuid4())
    sig_phi = str(uuid.uuid4())
    sig_owner = str(uuid.uuid4())
    visit_id = str(uuid.uuid4())
    follow_up = (date.today() + timedelta(days=14)).isoformat()

    ops = [
        {
            "type": "upsert_inspection",
            "payload": {
                "id": inspection_id,
                "premise_id": premise_id,
                "template_id": str(TEMPLATE_ID),
                "status": "completed",
                "started_at": now,
                "completed_at": now,
                "start_lat": 6.90,
                "start_lng": 79.85,
                "submit_lat": 6.90,
                "submit_lng": 79.85,
                "gps_status": "ok",
                "follow_up_date": follow_up,
                "updated_at": now,
            },
        },
        {
            "type": "upsert_answer",
            "payload": {
                "id": answer_id,
                "inspection_id": inspection_id,
                "item_id": item_id,
                "result": "fail",
                "notes": "Fridge at 12C",
                "updated_at": now,
            },
        },
        {
            "type": "upsert_photo_meta",
            "payload": {
                "id": photo_id,
                "inspection_id": inspection_id,
                "item_id": item_id,
                "sha256": "a" * 64,
                "captured_at": now,
                "latitude": 6.90,
                "longitude": 79.85,
                "updated_at": now,
            },
        },
        {
            "type": "upsert_violation",
            "payload": {
                "id": violation_id,
                "inspection_id": inspection_id,
                "item_id": item_id,
                "notice_type": "improvement_notice",
                "legal_provision": "Food Act temperature control",
                "deadline": follow_up,
                "accepted": True,
                "updated_at": now,
            },
        },
        {
            "type": "upsert_signature",
            "payload": {
                "id": sig_phi,
                "inspection_id": inspection_id,
                "signer_role": "phi",
                "signer_name": "PHI K. Dissanayake",
                "image_b64": "aaa",
                "signed_at": now,
                "updated_at": now,
            },
        },
        {
            "type": "upsert_signature",
            "payload": {
                "id": sig_owner,
                "inspection_id": inspection_id,
                "signer_role": "owner",
                "signer_name": "Nimal Perera",
                "image_b64": "bbb",
                "signed_at": now,
                "updated_at": now,
            },
        },
        {
            "type": "upsert_visit",
            "payload": {
                "id": visit_id,
                "premise_id": premise_id,
                "visit_date": follow_up,
                "reason": "follow_up",
                "status": "pending",
                "inspection_id": inspection_id,
                "notes": "Auto follow-up after improvement notice",
                "updated_at": now,
            },
        },
    ]

    first = client.post("/sync/push", headers=headers, json={"ops": ops})
    assert first.status_code == 200, first.text
    assert first.json()["applied"] == 7
    assert first.json()["errors"] == []

    second = client.post("/sync/push", headers=headers, json={"ops": ops})
    assert second.status_code == 200, second.text
    assert second.json()["applied"] == 7
    assert db.query(Inspection).filter(Inspection.id == uuid.UUID(inspection_id)).count() == 1

    pulled = client.get("/sync/pull", headers=headers).json()
    matching = [row for row in pulled["inspections"] if row["id"] == inspection_id]
    assert len(matching) == 1
    assert matching[0]["status"] == "completed"

    jpeg = BytesIO(b"\xff\xd8\xff\xd9")
    upload = client.post(
        "/media/photos",
        headers=headers,
        data={"photo_id": photo_id, "inspection_id": inspection_id},
        files={"file": ("evidence.jpg", jpeg, "image/jpeg")},
    )
    assert upload.status_code == 200, upload.text

    pdf = BytesIO(b"%PDF-1.4 demo")
    report = client.post(
        "/media/reports",
        headers=headers,
        data={"inspection_id": inspection_id},
        files={"file": ("report.pdf", pdf, "application/pdf")},
    )
    assert report.status_code == 200, report.text
