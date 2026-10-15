"""Fakes en memoria de la aplicación para tests unitarios de casos de uso."""

from __future__ import annotations

import json
from typing import Any
from uuid import UUID

from application.ports.email_sender import EmailMessage, EmailSender
from application.ports.movilidad import CountryProfileRepository, MovilidadEntryRepository, SizedEntry
from domain.entities.country_profile import CountryProfile
from domain.entities.movilidad_entry import MovilidadEntry
from fakes.fake_app_user_repository import FakeAppUserRepository
from fakes.fake_unit_of_work import FakeUnitOfWork


class FakeMovilidadEntryRepository(MovilidadEntryRepository):
    def __init__(self) -> None:
        self.rows: dict[str, Any] = {}

    def _keys(self, prefix: str) -> list[str]:
        return sorted(k for k in self.rows if k.startswith(prefix))

    def list_keys(self, prefix: str, limit: int) -> list[str]:
        return self._keys(prefix)[:limit]

    def list_page(self, prefix: str, after: str | None, limit: int) -> list[SizedEntry]:
        keys = [k for k in self._keys(prefix) if after is None or k > after][:limit]
        return [SizedEntry(MovilidadEntry(k, self.rows[k]), len(json.dumps(self.rows[k]))) for k in keys]

    def get(self, key: str) -> MovilidadEntry | None:
        return MovilidadEntry(key, self.rows[key]) if key in self.rows else None

    def upsert(self, key: str, value: Any) -> None:
        self.rows[key] = value

    def delete(self, key: str) -> None:
        self.rows.pop(key, None)


class FakeCountryProfileRepository(CountryProfileRepository):
    def __init__(self) -> None:
        self.rows: dict[UUID, CountryProfile] = {}

    def find_for_user(self, user_id: UUID) -> CountryProfile | None:
        return self.rows.get(user_id)


class FakeAppUnitOfWork(FakeUnitOfWork):
    """Comparte el estado entre transacciones, como una base real."""

    def __init__(self) -> None:
        super().__init__()
        self.entries = FakeMovilidadEntryRepository()
        self.profiles = FakeCountryProfileRepository()
        self.app_users = FakeAppUserRepository()

    def factory(self, principal=None) -> FakeAppUnitOfWork:
        return self


class FakeEmailSender(EmailSender):
    def __init__(self) -> None:
        self.sent: list[EmailMessage] = []

    def send(self, message: EmailMessage) -> str:
        self.sent.append(message)
        return f"msg-{len(self.sent)}"
