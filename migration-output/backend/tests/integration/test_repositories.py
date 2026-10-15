"""Repositories contra el esquema Aurora generado (tbl_olo_movilidad_*, trigger updated_at, search_path)."""

import os
from uuid import uuid4

import pytest

pytestmark = pytest.mark.integration

DATABASE_URL = os.environ.get("TEST_DATABASE_URL")
if not DATABASE_URL:
    pytest.skip("TEST_DATABASE_URL no definida", allow_module_level=True)

import psycopg  # noqa: E402

from application.dto.principal import Principal  # noqa: E402
from application.use_cases.perfiles import GetMyCountryProfileUseCase  # noqa: E402
from infrastructure.database.postgresql.app_unit_of_work import AppPostgresUnitOfWork  # noqa: E402
from infrastructure.database.postgresql.connection import (  # noqa: E402
    PostgresConnectionFactory,
    StaticCredentials,
)
from shared.settings import DatabaseSettings  # noqa: E402


@pytest.fixture(scope="module")
def factory():
    info = psycopg.conninfo.conninfo_to_dict(DATABASE_URL)
    settings = DatabaseSettings(
        secret_name="unused",
        name=info["dbname"],
        host=info.get("host", "localhost"),
        port=int(info.get("port", 5432)),
        sslmode="disable",
        connect_timeout=5,
        schemas=(),
    )
    return PostgresConnectionFactory(settings, StaticCredentials(info["user"], info.get("password", "")))


def _updated_at(uow, key):
    with uow.connection.cursor() as cur:
        cur.execute("SELECT updated_at FROM tbl_olo_movilidad_kv WHERE key = %s", (key,))
        return cur.fetchone()["updated_at"]


def test_kv_crud_pagination_and_updated_at_trigger(factory):
    run = uuid4().hex[:8]
    prefix = f"colaborador:{run}-"
    with AppPostgresUnitOfWork(factory, None) as uow:
        uow.entries.upsert(prefix + "a", {"id": "a", "nombre": "Ana"})
        uow.entries.upsert(prefix + "b", {"id": "b", "pais": "VE", "foto": "data:image/jpeg;base64,xx"})
        uow.commit()
    with AppPostgresUnitOfWork(factory, None) as uow:
        first = _updated_at(uow, prefix + "a")
    with AppPostgresUnitOfWork(factory, None) as uow:
        uow.entries.upsert(prefix + "a", {"id": "a", "nombre": "Ana María"})
        uow.commit()
    with AppPostgresUnitOfWork(factory, None) as uow:
        assert uow.entries.get(prefix + "a").value == {"id": "a", "nombre": "Ana María"}
        assert _updated_at(uow, prefix + "a") > first
        assert uow.entries.list_keys(prefix, 100) == [prefix + "a", prefix + "b"]
        page = uow.entries.list_page(prefix, None, 1)
        assert [s.entry.key for s in page] == [prefix + "a"] and page[0].size > 0
        assert [s.entry.key for s in uow.entries.list_page(prefix, prefix + "a", 10)] == [prefix + "b"]
        assert uow.entries.list_keys("100%_", 10) == []  # comodines escapados
        uow.entries.delete(prefix + "b")
        uow.commit()
    with AppPostgresUnitOfWork(factory, None) as uow:
        assert uow.entries.get(prefix + "b") is None


def test_country_profile_through_app_users_fk(factory):
    email = f"admin-{uuid4().hex[:6]}@ologistics.com"
    with AppPostgresUnitOfWork(factory, None, role="service_role") as uow:
        user_id, created = uow.app_users.link_or_create(f"sub-{uuid4()}", email)
        uow.commit()
    assert created
    with AppPostgresUnitOfWork(factory, None, role="service_role") as uow:
        with uow.connection.cursor() as cur:
            cur.execute(
                "INSERT INTO tbl_olo_movilidad_usuarios (user_id, email, pais, es_admin)"
                " VALUES (%s, %s, 'VE', false)",
                (user_id, email),
            )
        uow.commit()

    def factory_for(principal=None):
        return AppPostgresUnitOfWork(factory, principal)

    profile = GetMyCountryProfileUseCase(factory_for).execute(
        Principal(subject="s", email=email, user_id=user_id)
    )
    assert profile.to_dict() == {"pais": "VE", "es_admin": False, "email": email}
