"""Perfil de país del administrador autenticado (antes select en olo_movilidad_usuarios).

Política olo_mov_usuarios_select: cada usuario ve su propia fila. La UI solo lee la propia.
"""

from __future__ import annotations

from application.dto.principal import Principal
from application.ports.app_unit_of_work import UnitOfWorkFactory
from application.use_cases.common import require_user_id
from domain.entities.country_profile import CountryProfile


class GetMyCountryProfileUseCase:
    def __init__(self, uow_factory: UnitOfWorkFactory) -> None:
        self._uow_factory = uow_factory

    def execute(self, principal: Principal) -> CountryProfile | None:
        """None (204) si el usuario no tiene fila, como el maybeSingle() del origen."""
        user_id = require_user_id(principal)
        with self._uow_factory(principal) as uow:
            return uow.profiles.find_for_user(user_id)
