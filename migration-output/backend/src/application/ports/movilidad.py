"""Ports de persistencia del almacén de movilidad y de los perfiles de país."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any
from uuid import UUID

from domain.entities.country_profile import CountryProfile
from domain.entities.movilidad_entry import MovilidadEntry


@dataclass(frozen=True)
class SizedEntry:
    entry: MovilidadEntry
    size: int  # bytes del valor serializado, para acotar el tamaño de cada página


class MovilidadEntryRepository(ABC):
    @abstractmethod
    def list_keys(self, prefix: str, limit: int) -> list[str]:
        """Claves que empiezan por ``prefix``."""

    @abstractmethod
    def list_page(self, prefix: str, after: str | None, limit: int) -> list[SizedEntry]:
        """Registros con prefijo, ordenados por clave, posteriores a ``after``."""

    @abstractmethod
    def get(self, key: str) -> MovilidadEntry | None: ...

    @abstractmethod
    def upsert(self, key: str, value: Any) -> None: ...

    @abstractmethod
    def delete(self, key: str) -> None: ...


class CountryProfileRepository(ABC):
    @abstractmethod
    def find_for_user(self, user_id: UUID) -> CountryProfile | None: ...
