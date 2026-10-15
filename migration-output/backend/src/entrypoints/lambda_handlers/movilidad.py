"""Handlers HTTP del almacén de movilidad (públicos: enlaces de jefes/gerentes y administradores)."""

from __future__ import annotations

from entrypoints.lambda_handlers import container
from entrypoints.lambda_handlers.http_adapter import HttpRequest, api_handler


@api_handler
def list_movilidad_entries_handler(request: HttpRequest):
    return container.list_movilidad_entries().execute(
        request.query_str("prefix", ""),
        include_values=request.query_bool("values"),
        cursor=request.query_str("cursor"),
        limit=request.query_int("limit"),
    )


@api_handler
def get_movilidad_entry_handler(request: HttpRequest):
    return container.get_movilidad_entry().execute(request.path_param("key"))


@api_handler
def save_movilidad_entry_handler(request: HttpRequest):
    return container.save_movilidad_entry().execute(request.path_param("key"), request.json_body())


@api_handler
def delete_movilidad_entry_handler(request: HttpRequest):
    return container.delete_movilidad_entry().execute(request.path_param("key"))
