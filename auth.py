"""Auth endpoints: login, refresh, logout, me (ARCHITECTURE.md §8)."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.database import get_db
from core.dependencies import get_current_user
from core.security import (
    create_access_token,
    create_refresh_token,
    verify_password,
    verify_token,
)
from models.user import User
from schemas.auth import LoginRequest, RefreshRequest, TokenResponse, UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])


def _token_payload(user: User) -> dict:
    return {
        "sub": str(user.id),
        "org_id": str(user.org_id) if user.org_id else None,
        "role": user.role,
    }


def _build_token_response(user: User) -> TokenResponse:
    payload = _token_payload(user)
    return TokenResponse(
        access_token=create_access_token(payload),
        refresh_token=create_refresh_token(payload),
        user=UserResponse.model_validate(user),
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Verifies credentials and issues an access + refresh token pair."""
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario inactivo",
        )
    return _build_token_response(user)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Exchanges a valid refresh token for a fresh token pair."""
    payload = verify_token(body.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Se requiere un refresh token",
        )

    try:
        user_id = uuid.UUID(str(payload["sub"]))
    except (ValueError, KeyError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token inválido",
        ) from exc

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no válido",
        )
    return _build_token_response(user)


@router.post("/logout")
async def logout(_: User = Depends(get_current_user)) -> dict:
    """Stateless JWT — the client discards its tokens; nothing to revoke
    server-side (a denylist can be added later without changing the API)."""
    return {"message": "ok"}


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(current_user)
