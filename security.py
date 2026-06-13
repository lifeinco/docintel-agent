"""JWT creation / verification and password hashing (python-jose + passlib)."""
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

from core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def create_access_token(
    data: dict[str, Any],
    expires_delta: timedelta | None = None,
) -> str:
    """Short-lived access token. `data` should carry sub / org_id / role."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def create_refresh_token(data: dict[str, Any]) -> str:
    """Long-lived (30d) refresh token."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.refresh_token_expire_days
    )
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def verify_token(token: str) -> dict[str, Any]:
    """Decodes and validates a JWT. Raises 401 on any failure."""
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    if payload.get("sub") is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sin subject",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
