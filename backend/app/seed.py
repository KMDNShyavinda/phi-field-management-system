from __future__ import annotations

import uuid
from datetime import date, timedelta

from sqlalchemy.orm import Session

from app.auth import hash_password
from app.database import SessionLocal, engine
from app.models import (
    Base,
    ChecklistItem,
    ChecklistTemplate,
    Premise,
    ScheduledVisit,
    User,
)

PHI_ID = uuid.UUID("00000000-0000-4000-8000-000000000001")
TEMPLATE_ID = uuid.UUID("00000000-0000-4000-8000-000000000010")
MOH_AREA = "Colombo MOH"

PREMISES = [
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000101"),
        "name": "Lanka Spice Hotel",
        "address": "42 Galle Road, Colombo 03",
        "owner_name": "Nimal Perera",
        "owner_phone": "0771234567",
        "latitude": 6.9012,
        "longitude": 79.8540,
        "risk": "high",
        "compliance_score": 48,
    },
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000102"),
        "name": "Green Leaf Restaurant",
        "address": "12 Flower Road, Colombo 07",
        "owner_name": "Amali Silva",
        "owner_phone": "0715558899",
        "latitude": 6.9108,
        "longitude": 79.8605,
        "risk": "medium",
        "compliance_score": 72,
    },
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000103"),
        "name": "City Bakery",
        "address": "8 Main Street, Pettah",
        "owner_name": "Rizwan Mohamed",
        "owner_phone": "0752223344",
        "latitude": 6.9360,
        "longitude": 79.8500,
        "risk": "medium",
        "compliance_score": 68,
    },
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000104"),
        "name": "Ocean Catch Seafood",
        "address": "21 Marine Drive, Colombo 04",
        "owner_name": "Kumari Jayasuriya",
        "owner_phone": "0779988776",
        "latitude": 6.8794,
        "longitude": 79.8599,
        "risk": "high",
        "compliance_score": 41,
    },
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000105"),
        "name": "School Canteen — Royal College",
        "address": "Rajakeeya Mawatha, Colombo 07",
        "owner_name": "Saman Wickramasinghe",
        "owner_phone": "0112580000",
        "latitude": 6.9048,
        "longitude": 79.8607,
        "risk": "low",
        "compliance_score": 88,
    },
    {
        "id": uuid.UUID("00000000-0000-4000-8000-000000000106"),
        "name": "Kade Street Grocery",
        "address": "5 Temple Road, Borella",
        "owner_name": "Chamari Fernando",
        "owner_phone": "0761112233",
        "latitude": 6.9150,
        "longitude": 79.8772,
        "risk": "low",
        "compliance_score": 81,
    },
]

CHECKLIST_ITEMS = [
    (
        "COLD_STORAGE",
        "Cold storage temperature",
        "Refrigerated food held between 2°C and 5°C. Probe or display thermometer acceptable.",
        "Food Act No. 26 of 1980 — temperature control of stored perishable food.",
    ),
    (
        "HOT_HOLDING",
        "Hot holding / cooking temperature",
        "Ready-to-eat hot food held at or above 63°C.",
        "Food Act No. 26 of 1980 — hot-holding temperature of ready-to-eat food.",
    ),
    (
        "PEST_CONTROL",
        "Pest control",
        "No evidence of rodents, cockroaches or flies in food rooms.",
        "Food Act No. 26 of 1980 — premises must be kept free of pest infestation.",
    ),
    (
        "WATER_SUPPLY",
        "Potable water supply",
        "Adequate, clean water for washing food, utensils and hands.",
        "Food Act No. 26 of 1980 — potable water for food handling.",
    ),
    (
        "WASTE_DISPOSAL",
        "Waste disposal",
        "Covered bins, regular removal, no overflow near prep areas.",
        "Food Act No. 26 of 1980 — waste storage and disposal.",
    ),
    (
        "PERSONAL_HYGIENE",
        "Personal hygiene & handwashing",
        "Handwash basin with soap; clean uniforms; no uncovered wounds.",
        "Food Act No. 26 of 1980 — food handler hygiene.",
    ),
    (
        "FOOD_LABELLING",
        "Labelling and expiry control",
        "Packaged foods labelled; stock rotated; no expired goods on sale.",
        "Food Act No. 26 of 1980 — labelling / expiry control.",
    ),
    (
        "PREP_SURFACES",
        "Cleanliness of prep surfaces",
        "Food-contact surfaces clean, intact and sanitised.",
        "Food Act No. 26 of 1980 — sanitary condition of food rooms.",
    ),
]


def seed(db: Session) -> None:
    Base.metadata.create_all(bind=engine)

    user = db.get(User, PHI_ID)
    if user is None:
        user = User(
            id=PHI_ID,
            email="phi@moh.lk",
            hashed_password=hash_password("phi12345"),
            full_name="PHI K. Dissanayake",
            role="phi",
            moh_area=MOH_AREA,
        )
        db.add(user)

    template = db.get(ChecklistTemplate, TEMPLATE_ID)
    if template is None:
        template = ChecklistTemplate(id=TEMPLATE_ID, name="Food premises hygiene (MVP)")
        db.add(template)

    for index, (code, title, description, hint) in enumerate(CHECKLIST_ITEMS, start=1):
        item_id = uuid.UUID(f"00000000-0000-4000-8000-0000000002{index:02d}")
        if db.get(ChecklistItem, item_id) is None:
            db.add(
                ChecklistItem(
                    id=item_id,
                    template_id=TEMPLATE_ID,
                    code=code,
                    title=title,
                    description=description,
                    sort_order=index,
                    legal_hint=hint,
                )
            )

    for row in PREMISES:
        if db.get(Premise, row["id"]) is None:
            db.add(
                Premise(
                    qr_code=f"phi://premise/{row['id']}",
                    moh_area=MOH_AREA,
                    **row,
                )
            )

    today = date.today()
    visit_specs = [
        (PREMISES[0]["id"], "high_risk", "Priority high-risk premises"),
        (PREMISES[1]["id"], "planned", "Routine programmed visit"),
        (PREMISES[3]["id"], "complaint", "Public complaint — alleged spoilage"),
        (PREMISES[2]["id"], "follow_up", "Follow-up on previous notice"),
        (PREMISES[4]["id"], "planned", "School canteen programmed visit"),
    ]
    for index, (premise_id, reason, notes) in enumerate(visit_specs, start=1):
        visit_id = uuid.UUID(f"00000000-0000-4000-8000-0000000003{index:02d}")
        if db.get(ScheduledVisit, visit_id) is None:
            visit_date = today if index < 5 else today + timedelta(days=1)
            db.add(
                ScheduledVisit(
                    id=visit_id,
                    premise_id=premise_id,
                    officer_id=PHI_ID,
                    visit_date=visit_date,
                    reason=reason,
                    status="pending",
                    notes=notes,
                )
            )

    db.commit()


def main() -> None:
    db = SessionLocal()
    try:
        seed(db)
        print("Seed complete. Demo PHI: phi@moh.lk / phi12345")
    finally:
        db.close()


if __name__ == "__main__":
    main()
