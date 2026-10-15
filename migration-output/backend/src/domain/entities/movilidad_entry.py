"""Registro del almacén key-value de movilidad (tbl_olo_movilidad_kv).

Las claves llevan prefijo por tipo de dato: ``colaborador:<id>``, ``evaluacion:<id>``,
``historico:<id>`` y las claves sueltas ``directorio`` y ``config``.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from domain.exceptions import ValidationError

MAX_KEY_LENGTH = 1000


@dataclass(frozen=True)
class MovilidadEntry:
    key: str
    value: Any

    def to_dict(self) -> dict[str, Any]:
        return {"key": self.key, "value": self.value}


def normalize_key(raw: object) -> str:
    key = "" if raw is None else str(raw)
    if not key.strip():
        raise ValidationError("La clave es obligatoria.", details={"field": "key"})
    if len(key) > MAX_KEY_LENGTH:
        raise ValidationError(
            f"La clave no puede superar {MAX_KEY_LENGTH} caracteres.", details={"field": "key"}
        )
    return key


def normalize_prefix(raw: object) -> str:
    prefix = "" if raw is None else str(raw)
    if len(prefix) > MAX_KEY_LENGTH:
        raise ValidationError(
            f"El prefijo no puede superar {MAX_KEY_LENGTH} caracteres.", details={"field": "prefix"}
        )
    return prefix
