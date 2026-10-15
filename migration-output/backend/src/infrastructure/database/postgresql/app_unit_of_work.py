"""UnitOfWork de la aplicación: arma los repositories sobre la conexión de la transacción."""

from __future__ import annotations

import psycopg

from infrastructure.database.postgresql.app_user_repository import PostgresAppUserRepository
from infrastructure.database.postgresql.movilidad_repository import (
    PostgresCountryProfileRepository,
    PostgresMovilidadEntryRepository,
)
from infrastructure.database.postgresql.unit_of_work import PostgresUnitOfWork


class AppPostgresUnitOfWork(PostgresUnitOfWork):
    def _build_repositories(self, connection: psycopg.Connection) -> None:
        self.entries = PostgresMovilidadEntryRepository(connection)
        self.profiles = PostgresCountryProfileRepository(connection)
        self.app_users = PostgresAppUserRepository(connection)
