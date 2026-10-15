"""Perfil de país de un administrador autenticado (tbl_olo_movilidad_usuarios).

La interfaz lo usa para acotar la vista: país asignado = restricción dura; ``es_admin`` o país
nulo = administrador global que elige el país en el selector.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class CountryProfile:
    pais: str | None
    es_admin: bool
    email: str | None

    def to_dict(self) -> dict[str, Any]:
        """Forma que leía la UI: select('pais,es_admin,email')."""
        return {"pais": self.pais, "es_admin": self.es_admin, "email": self.email}
