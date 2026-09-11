import uuid
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import Premise
from app.risk_engine import calculate_premise_risk

def test_risk_calc():
    db = SessionLocal()
    try:
        premises = db.query(Premise).all()
        for p in premises:
            print(f"Before: {p.name} - Score: {p.compliance_score}, Risk: {p.risk}")
            calculate_premise_risk(db, p.id)
            print(f"After: {p.name} - Score: {p.compliance_score}, Risk: {p.risk}")
        db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    test_risk_calc()
