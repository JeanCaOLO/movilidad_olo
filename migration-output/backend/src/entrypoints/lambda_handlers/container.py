"""Composition root: arma casos de uso con sus adapters. Todo perezoso (se crea en el primer uso)."""

from __future__ import annotations

from functools import lru_cache

from application.dto.principal import Principal
from application.use_cases.movilidad import (
    DeleteMovilidadEntryUseCase,
    GetMovilidadEntryUseCase,
    ListMovilidadEntriesUseCase,
    SaveMovilidadEntryUseCase,
)
from application.use_cases.notificaciones import SendEvaluationEmailUseCase
from application.use_cases.perfiles import GetMyCountryProfileUseCase
from application.use_cases.resolve_current_user import ResolveCurrentUserUseCase
from entrypoints.lambda_handlers.bootstrap import connection_factory
from infrastructure.aws.ses_email_sender import SesEmailSender
from infrastructure.database.postgresql.app_unit_of_work import AppPostgresUnitOfWork
from shared.settings import env


def uow_factory(principal: Principal | None = None) -> AppPostgresUnitOfWork:
    return AppPostgresUnitOfWork(connection_factory(), principal)


@lru_cache(maxsize=1)
def _current_user() -> ResolveCurrentUserUseCase:
    return ResolveCurrentUserUseCase(
        lambda: AppPostgresUnitOfWork(connection_factory(), None, role="service_role")
    )


def resolve_principal(principal: Principal) -> Principal:
    return _current_user().execute(principal)


@lru_cache(maxsize=1)
def _email_sender() -> SesEmailSender:
    return SesEmailSender(env("SES_FROM_EMAIL", required=True))


def list_movilidad_entries() -> ListMovilidadEntriesUseCase:
    return ListMovilidadEntriesUseCase(uow_factory)


def get_movilidad_entry() -> GetMovilidadEntryUseCase:
    return GetMovilidadEntryUseCase(uow_factory)


def save_movilidad_entry() -> SaveMovilidadEntryUseCase:
    return SaveMovilidadEntryUseCase(uow_factory)


def delete_movilidad_entry() -> DeleteMovilidadEntryUseCase:
    return DeleteMovilidadEntryUseCase(uow_factory)


def get_my_country_profile() -> GetMyCountryProfileUseCase:
    return GetMyCountryProfileUseCase(uow_factory)


def send_evaluation_email() -> SendEvaluationEmailUseCase:
    return SendEvaluationEmailUseCase(_email_sender())
