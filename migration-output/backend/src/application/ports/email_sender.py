"""Port de envío de correo (antes Edge Function send-eval-email)."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class EmailMessage:
    to: str
    subject: str
    text: str
    html: str
    cc: tuple[str, ...] = ()


class EmailSender(ABC):
    @abstractmethod
    def send(self, message: EmailMessage) -> str:
        """Envía el correo (texto + HTML) desde el remitente del sistema. Devuelve el id del envío."""
