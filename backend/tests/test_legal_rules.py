from datetime import date, timedelta

from app.legal_rules import suggest_notice


def test_cold_storage_is_14_day_notice() -> None:
    notice = suggest_notice("COLD_STORAGE", from_date=date(2026, 9, 1))
    assert notice["notice_type"] == "improvement_notice"
    assert notice["deadline"] == date(2026, 9, 15)
    assert notice["days"] == 14


def test_unknown_code_defaults_to_14_days() -> None:
    notice = suggest_notice("OTHER", from_date=date(2026, 1, 1))
    assert notice["deadline"] == date(2026, 1, 1) + timedelta(days=14)
