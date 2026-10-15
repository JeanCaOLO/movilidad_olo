"""Reglas compartidas por los casos de uso."""

from __future__ import annotations

from uuid import UUID

from application.dto.principal import Principal
from domain.exceptions import UnauthorizedError


def require_user_id(principal: Principal) -> UUID:
    if principal.user_id is None:
        raise UnauthorizedError("Se requiere un usuario de la aplicación.")
    return principal.user_id
