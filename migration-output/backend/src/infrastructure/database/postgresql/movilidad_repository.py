"""Adapters PostgreSQL del almacén de movilidad (tbl_olo_movilidad_kv) y de los perfiles de país
(tbl_olo_movilidad_usuarios). updated_at lo mantienen el DEFAULT y el trigger de la tabla."""

from __future__ import annotations

from typing import Any
from uuid import UUID

import psycopg
from psycopg.types.json import Jsonb

from application.ports.movilidad import CountryProfileRepository, MovilidadEntryRepository, SizedEntry
from domain.entities.country_profile import CountryProfile
from domain.entities.movilidad_entry import MovilidadEntry

_LIST_KEYS_SQL = """
SELECT key FROM tbl_olo_movilidad_kv
WHERE key LIKE %(pattern)s ESCAPE '\\'
ORDER BY key LIMIT %(limit)s
"""
_LIST_PAGE_SQL = """
SELECT key, value, octet_length(coalesce(value::text, 'null')) AS size FROM tbl_olo_movilidad_kv
WHERE key LIKE %(pattern)s ESCAPE '\\' AND (%(after)s::text IS NULL OR key > %(after)s)
ORDER BY key LIMIT %(limit)s
"""
_GET_SQL = "SELECT key, value FROM tbl_olo_movilidad_kv WHERE key = %s"
_UPSERT_SQL = """
INSERT INTO tbl_olo_movilidad_kv (key, value) VALUES (%s, %s)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value
"""
_DELETE_SQL = "DELETE FROM tbl_olo_movilidad_kv WHERE key = %s"
_PROFILE_SQL = "SELECT pais, es_admin, email FROM tbl_olo_movilidad_usuarios WHERE user_id = %s"


def _like_prefix(prefix: str) -> str:
    escaped = prefix.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return escaped + "%"


class PostgresMovilidadEntryRepository(MovilidadEntryRepository):
    def __init__(self, connection: psycopg.Connection) -> None:
        self._connection = connection

    def list_keys(self, prefix: str, limit: int) -> list[str]:
        with self._connection.cursor() as cursor:
            cursor.execute(_LIST_KEYS_SQL, {"pattern": _like_prefix(prefix), "limit": limit})
            return [row["key"] for row in cursor.fetchall()]

    def list_page(self, prefix: str, after: str | None, limit: int) -> list[SizedEntry]:
        with self._connection.cursor() as cursor:
            cursor.execute(_LIST_PAGE_SQL, {"pattern": _like_prefix(prefix), "after": after, "limit": limit})
            return [
                SizedEntry(MovilidadEntry(row["key"], row["value"]), int(row["size"]))
                for row in cursor.fetchall()
            ]

    def get(self, key: str) -> MovilidadEntry | None:
        with self._connection.cursor() as cursor:
            cursor.execute(_GET_SQL, (key,))
            row = cursor.fetchone()
        return MovilidadEntry(row["key"], row["value"]) if row else None

    def upsert(self, key: str, value: Any) -> None:
        with self._connection.cursor() as cursor:
            cursor.execute(_UPSERT_SQL, (key, Jsonb(value)))

    def delete(self, key: str) -> None:
        with self._connection.cursor() as cursor:
            cursor.execute(_DELETE_SQL, (key,))


class PostgresCountryProfileRepository(CountryProfileRepository):
    def __init__(self, connection: psycopg.Connection) -> None:
        self._connection = connection

    def find_for_user(self, user_id: UUID) -> CountryProfile | None:
        with self._connection.cursor() as cursor:
            cursor.execute(_PROFILE_SQL, (user_id,))
            row = cursor.fetchone()
        if row is None:
            return None
        return CountryProfile(pais=row["pais"], es_admin=bool(row["es_admin"]), email=row["email"])
