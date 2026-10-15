"""Envío de correos del sistema (antes Edge Function send-eval-email, SMTP de Gmail).

Mismo contrato y reglas que la función original: payload ``{to, subject, body, cc?}``;
destinatario obligatorio y válido; asunto y cuerpo obligatorios; ``cc`` solo si es un correo
válido (si no, se ignora); se envía texto plano y una versión HTML con los saltos de línea
respetados y los enlaces resaltados. Respuesta ``{ok: true}``.
"""

from __future__ import annotations

import html
import re
from typing import Any

from application.ports.email_sender import EmailMessage, EmailSender
from domain.exceptions import ValidationError

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
_URL_RE = re.compile(r"(https?://[^\s]+)")
MAX_SUBJECT_LENGTH = 998
MAX_BODY_LENGTH = 200_000


def to_html(text: str) -> str:
    """Versión HTML del original: escapa, resalta enlaces y convierte saltos de línea."""
    escaped = html.escape(text, quote=True).replace("&#x27;", "'")
    linked = _URL_RE.sub(r'<a href="\1" style="color:#00735E;font-weight:bold">\1</a>', escaped)
    return (
        '<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;line-height:1.6;color:#1A1A1A">'
        + linked.replace("\n", "<br>")
        + "</div>"
    )


class SendEvaluationEmailUseCase:
    def __init__(self, sender: EmailSender) -> None:
        self._sender = sender

    def execute(self, body: dict[str, Any]) -> dict[str, Any]:
        to = str(body.get("to") or "").strip()
        subject = str(body.get("subject") or "").strip()
        text = str(body.get("body") or "").strip()
        cc_raw = str(body.get("cc") or "").strip()
        if not _EMAIL_RE.match(to):
            raise ValidationError("Destinatario inválido: " + to, details={"field": "to"})
        if not subject or not text:
            raise ValidationError("Faltan asunto o cuerpo del correo")
        if len(subject) > MAX_SUBJECT_LENGTH or len(text) > MAX_BODY_LENGTH:
            raise ValidationError("Contenido demasiado largo")
        cc = (cc_raw,) if _EMAIL_RE.match(cc_raw) else ()
        self._sender.send(EmailMessage(to, subject, text, to_html(text), cc))
        return {"ok": True}
