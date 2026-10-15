"""Adapter de EmailSender sobre Amazon SES v2 (multipart texto + HTML, UTF-8)."""

from __future__ import annotations

from email.header import Header
from email.utils import formataddr
from typing import Any

import boto3

from application.ports.email_sender import EmailMessage, EmailSender

DEFAULT_FROM_NAME = "Comunicaciones OLO"  # MAIL_FROM_NAME por defecto de la función original


class SesEmailSender(EmailSender):
    def __init__(
        self, from_address: str, from_name: str = DEFAULT_FROM_NAME, client: Any | None = None
    ) -> None:
        self._from = formataddr((str(Header(from_name, "utf-8")), from_address))
        self._client = client or boto3.client("sesv2")

    def send(self, message: EmailMessage) -> str:
        destination: dict[str, list[str]] = {"ToAddresses": [message.to]}
        if message.cc:
            destination["CcAddresses"] = list(message.cc)
        response = self._client.send_email(
            FromEmailAddress=self._from,
            Destination=destination,
            Content={
                "Simple": {
                    "Subject": {"Data": message.subject, "Charset": "UTF-8"},
                    "Body": {
                        "Text": {"Data": message.text, "Charset": "UTF-8"},
                        "Html": {"Data": message.html, "Charset": "UTF-8"},
                    },
                }
            },
        )
        return str(response.get("MessageId", ""))
