"""Casos de uso del almacén key-value de movilidad (antes PostgREST sobre olo_movilidad_kv).

Autorización: en el origen las políticas permisivas olo_mov_select/insert/update/delete
(``true`` para ``anon`` y ``authenticated``) dan acceso completo a todos, y se combinan con OR con
las políticas por país (olo_mov_kv_*), que por eso no restringen nada. Se conserva ese acceso
efectivo: lectura y escritura completas; el acotamiento por país lo hace la interfaz.
"""

from __future__ import annotations

from typing import Any
from urllib.parse import unquote

from application.ports.app_unit_of_work import UnitOfWorkFactory
from domain.entities.movilidad_entry import MovilidadEntry, normalize_key, normalize_prefix
from domain.exceptions import NotFoundError, ValidationError

MAX_KEYS = 10000  # el original listaba claves con .limit(10000)
DEFAULT_PAGE_ROWS = 500
MAX_PAGE_ROWS = 1000
PAGE_BYTE_BUDGET = 4_000_000  # bajo el límite de 6 MB de respuesta de Lambda


def parse_entry_key(raw: object) -> str:
    """La clave llega como parámetro de ruta (encodeURIComponent en el front)."""
    text = "" if raw is None else str(raw)
    return normalize_key(unquote(text) if "%" in text else text)


class ListMovilidadEntriesUseCase:
    def __init__(self, uow_factory: UnitOfWorkFactory) -> None:
        self._uow_factory = uow_factory

    def execute(
        self,
        prefix: object,
        *,
        include_values: bool,
        cursor: str | None = None,
        limit: int | None = None,
    ) -> dict[str, Any]:
        clean_prefix = normalize_prefix(prefix)
        rows = DEFAULT_PAGE_ROWS if limit is None else limit
        if rows < 1 or rows > MAX_PAGE_ROWS:
            raise ValidationError(
                f"'limit' debe estar entre 1 y {MAX_PAGE_ROWS}.", details={"field": "limit"}
            )
        with self._uow_factory(None) as uow:
            if not include_values:
                return {"keys": uow.entries.list_keys(clean_prefix, MAX_KEYS)}
            page = uow.entries.list_page(clean_prefix, cursor, rows)
        items: list[MovilidadEntry] = []
        used = 0
        for sized in page:
            if items and used + sized.size > PAGE_BYTE_BUDGET:
                break
            items.append(sized.entry)
            used += sized.size
        more = len(items) < len(page) or len(page) == rows
        return {"items": items, "next_cursor": items[-1].key if more and items else None}


class GetMovilidadEntryUseCase:
    def __init__(self, uow_factory: UnitOfWorkFactory) -> None:
        self._uow_factory = uow_factory

    def execute(self, raw_key: object) -> MovilidadEntry:
        key = parse_entry_key(raw_key)
        with self._uow_factory(None) as uow:
            entry = uow.entries.get(key)
        if entry is None:
            raise NotFoundError("El registro no existe.")
        return entry


class SaveMovilidadEntryUseCase:
    """Upsert por clave (antes upsert({key, value}, {onConflict: 'key'}))."""

    def __init__(self, uow_factory: UnitOfWorkFactory) -> None:
        self._uow_factory = uow_factory

    def execute(self, raw_key: object, body: dict[str, Any]) -> None:
        key = parse_entry_key(raw_key)
        if "value" not in body:
            raise ValidationError("Falta 'value' en el cuerpo.", details={"field": "value"})
        with self._uow_factory(None) as uow:
            uow.entries.upsert(key, body["value"])
            uow.commit()


class DeleteMovilidadEntryUseCase:
    def __init__(self, uow_factory: UnitOfWorkFactory) -> None:
        self._uow_factory = uow_factory

    def execute(self, raw_key: object) -> None:
        key = parse_entry_key(raw_key)
        with self._uow_factory(None) as uow:
            uow.entries.delete(key)
            uow.commit()
