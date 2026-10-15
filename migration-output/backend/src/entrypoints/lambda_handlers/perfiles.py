"""Handler GET /me/country-profile: perfil de país del administrador autenticado."""

from __future__ import annotations

from entrypoints.lambda_handlers import container
from entrypoints.lambda_handlers.http_adapter import HttpRequest, api_handler


@api_handler(principal_resolver=container.resolve_principal)
def get_my_country_profile_handler(request: HttpRequest):
    return container.get_my_country_profile().execute(request.require_principal())
