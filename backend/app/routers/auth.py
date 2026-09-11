from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import create_access_token, create_refresh_token, decode_token, verify_password, hash_password
from app.database import get_db
from app.models import User
from app.otp import generate_otp, verify_otp as verify_otp_code
from app.schemas import LoginRequest, RefreshRequest, TokenResponse, UserOut, OtpRequest, OtpVerifyRequest, PasswordResetRequest, OtpResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.query(User).filter(User.email == body.email.lower().strip()).first()
    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
        user=UserOut.model_validate(user),
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user_id = decode_token(body.refresh_token, "refresh")
    user = db.get(User, UUID(user_id))
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
        user=UserOut.model_validate(user),
    )


@router.post("/request-otp", response_model=OtpResponse)
def request_otp(body: OtpRequest, db: Session = Depends(get_db)):
    """Send OTP to user's email for password reset."""
    user = db.query(User).filter(User.email == body.email.lower().strip()).first()
    if user is None:
        # Don't reveal if email exists or not (security)
        return OtpResponse(message="If the email exists, an OTP has been sent.")

    code = generate_otp(body.email)

    # In production: send via email/SMS. For demo: return in response.
    print(f"[OTP] Code for {body.email}: {code}")

    return OtpResponse(
        message="OTP sent successfully. Valid for 10 minutes.",
        otp_code=code,  # Remove this in production! Only for demo/testing.
    )


@router.post("/verify-otp")
def verify_otp_endpoint(body: OtpVerifyRequest, db: Session = Depends(get_db)):
    """Verify OTP code."""
    user = db.query(User).filter(User.email == body.email.lower().strip()).first()
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid email or OTP.")

    if not verify_otp_code(body.email, body.otp_code):
        raise HTTPException(status_code=400, detail="Invalid or expired OTP.")

    return {"message": "OTP verified successfully. You can now reset your password."}


@router.post("/reset-password")
def reset_password(body: PasswordResetRequest, db: Session = Depends(get_db)):
    """Reset password after OTP verification."""
    user = db.query(User).filter(User.email == body.email.lower().strip()).first()
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid email.")

    # Re-generate and verify OTP in one step for security
    if not verify_otp_code(body.email, body.otp_code):
        raise HTTPException(status_code=400, detail="Invalid or expired OTP. Please request a new one.")

    # Update password
    user.hashed_password = hash_password(body.new_password)
    db.commit()

    return {"message": "Password reset successfully. You can now login with your new password."}
