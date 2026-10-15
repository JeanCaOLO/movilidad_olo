import pytest

from application.use_cases.notificaciones import SendEvaluationEmailUseCase, to_html
from domain.exceptions import ValidationError
from fakes.fake_app_unit_of_work import FakeEmailSender


def test_sends_text_and_html_like_send_eval_email():
    sender = FakeEmailSender()
    result = SendEvaluationEmailUseCase(sender).execute(
        {
            "to": " jefe@ologistics.com ",
            "subject": " Evaluación ",
            "body": "Hola\nEntra: https://x.com/a",
            "cc": "rh@x.com",
        }
    )
    assert result == {"ok": True}
    message = sender.sent[0]
    assert (message.to, message.subject, message.text) == (
        "jefe@ologistics.com",
        "Evaluación",
        "Hola\nEntra: https://x.com/a",
    )
    assert message.cc == ("rh@x.com",)
    assert 'Hola<br>Entra: <a href="https://x.com/a" style="color:#00735E;font-weight:bold">' in message.html


def test_html_escapes_markup():
    assert "&lt;b&gt;&amp;&quot;" in to_html('<b>&"')


@pytest.mark.parametrize("cc", ["nadie", "a@x.com, b@x.com", ""])
def test_invalid_or_multiple_cc_is_ignored_like_the_original(cc):
    sender = FakeEmailSender()
    SendEvaluationEmailUseCase(sender).execute({"to": "j@x.com", "subject": "s", "body": "b", "cc": cc})
    assert sender.sent[0].cc == ()


@pytest.mark.parametrize(
    ("payload", "message"),
    [
        ({"to": "", "subject": "s", "body": "b"}, "Destinatario inválido: "),
        ({"to": "no-es-correo", "subject": "s", "body": "b"}, "Destinatario inválido: no-es-correo"),
        ({"to": "j@x.com", "subject": "  ", "body": "b"}, "Faltan asunto o cuerpo del correo"),
        ({"to": "j@x.com", "subject": "s", "body": "   "}, "Faltan asunto o cuerpo del correo"),
    ],
)
def test_rejects_invalid_payloads_with_original_messages(payload, message):
    sender = FakeEmailSender()
    with pytest.raises(ValidationError) as error:
        SendEvaluationEmailUseCase(sender).execute(payload)
    assert error.value.message == message
    assert sender.sent == []
