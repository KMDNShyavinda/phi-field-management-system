"""
Simple in-memory OTP store for password reset.
In production, use Redis or a database table with expiry.
"""
import random
import string
from datetime import datetime, timedelta, timezone

_otp_store: dict[str, dict] = {}

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 10


def generate_otp(email: str) -> str:
    """Generate a 6-digit OTP for the given email."""
    code = ''.join(random.choices(string.digits, k=OTP_LENGTH))
    _otp_store[email.lower().strip()] = {
        'code': code,
        'created_at': datetime.now(timezone.utc),
        'attempts': 0,
    }
    return code


def verify_otp(email: str, code: str) -> bool:
    """Verify OTP for the given email. Returns True if valid."""
    key = email.lower().strip()
    entry = _otp_store.get(key)
    if entry is None:
        return False

    # Check expiry
    elapsed = datetime.now(timezone.utc) - entry['created_at']
    if elapsed > timedelta(minutes=OTP_EXPIRY_MINUTES):
        del _otp_store[key]
        return False

    # Check max attempts (prevent brute force)
    entry['attempts'] += 1
    if entry['attempts'] > 5:
        del _otp_store[key]
        return False

    if entry['code'] != code:
        return False

    # Valid - remove used OTP
    del _otp_store[key]
    return True
