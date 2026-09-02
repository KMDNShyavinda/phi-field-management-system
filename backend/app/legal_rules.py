"""Deterministic Food Act notice suggestions used by both API docs and the mobile app."""

from __future__ import annotations

from datetime import date, timedelta

RULES: dict[str, dict[str, object]] = {
    "COLD_STORAGE": {
        "notice_type": "improvement_notice",
        "days": 14,
        "provision": "Food Act No. 26 of 1980 — temperature control of stored perishable food is inadequate.",
    },
    "HOT_HOLDING": {
        "notice_type": "improvement_notice",
        "days": 14,
        "provision": "Food Act No. 26 of 1980 — hot-holding temperature of ready-to-eat food is inadequate.",
    },
    "PEST_CONTROL": {
        "notice_type": "improvement_notice",
        "days": 7,
        "provision": "Food Act No. 26 of 1980 — premises must be kept free of pest infestation.",
    },
    "WATER_SUPPLY": {
        "notice_type": "improvement_notice",
        "days": 7,
        "provision": "Food Act No. 26 of 1980 — potable water supply for food handling is unsatisfactory.",
    },
    "WASTE_DISPOSAL": {
        "notice_type": "improvement_notice",
        "days": 7,
        "provision": "Food Act No. 26 of 1980 — waste storage and disposal arrangements are unsatisfactory.",
    },
    "PERSONAL_HYGIENE": {
        "notice_type": "improvement_notice",
        "days": 7,
        "provision": "Food Act No. 26 of 1980 — food handler hygiene and hand-washing facilities are inadequate.",
    },
    "FOOD_LABELLING": {
        "notice_type": "improvement_notice",
        "days": 14,
        "provision": "Food Act No. 26 of 1980 — labelling / expiry control of displayed food is unsatisfactory.",
    },
    "PREP_SURFACES": {
        "notice_type": "improvement_notice",
        "days": 7,
        "provision": "Food Act No. 26 of 1980 — food contact surfaces are not maintained in a sanitary condition.",
    },
}


def suggest_notice(item_code: str, from_date: date | None = None) -> dict[str, object]:
    today = from_date or date.today()
    rule = RULES.get(item_code) or {
        "notice_type": "improvement_notice",
        "days": 14,
        "provision": "Food Act No. 26 of 1980 — general sanitary requirement not met.",
    }
    days = int(rule["days"])
    return {
        "notice_type": rule["notice_type"],
        "days": days,
        "legal_provision": rule["provision"],
        "deadline": today + timedelta(days=days),
    }
