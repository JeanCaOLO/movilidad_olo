"""Handler POST /notifications/evaluation-emails (antes Edge Function send-eval-email)."""

from __future__ import annotations

from entrypoints.lambda_handlers import container
from entrypoints.lambda_handlers.http_adapter import HttpRequest, api_handler


@api_handler
def send_evaluation_email_handler(request: HttpRequest):
    return container.send_evaluation_email().execute(request.json_body())
