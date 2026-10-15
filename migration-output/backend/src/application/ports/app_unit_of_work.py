"""Unidad de trabajo de la aplicación: repositories disponibles dentro de una transacción."""

from __future__ import annotations

from collections.abc import Callable
from typing import Protocol, Self

from application.dto.principal import Principal
from application.ports.app_user_repository import AppUserRepository
from application.ports.movilidad import CountryProfileRepository, MovilidadEntryRepository


class AppUnitOfWork(Protocol):
    entries: MovilidadEntryRepository
    profiles: CountryProfileRepository
    app_users: AppUserRepository

    def commit(self) -> None: ...

    def after_commit(self, callback: Callable[[], None]) -> None: ...

    def __enter__(self) -> Self: ...

    def __exit__(self, exc_type, exc, tb) -> None: ...


UnitOfWorkFactory = Callable[[Principal | None], AppUnitOfWork]
