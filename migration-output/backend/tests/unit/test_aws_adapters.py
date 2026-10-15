from application.ports.email_sender import EmailMessage
from infrastructure.aws.ses_email_sender import SesEmailSender


class _Recorder:
    def __init__(self, reply):
        self.reply = reply
        self.calls = []

    def send_email(self, **kwargs):
        self.calls.append(kwargs)
        return self.reply


def test_ses_sender_sends_multipart_from_system_sender_with_display_name():
    client = _Recorder({"MessageId": "abc"})
    sender = SesEmailSender("comunicaciones@ologistics.com", client=client)
    message = EmailMessage("j@x.com", "Asunto", "Cuerpo", "<div>Cuerpo</div>", ("c@x.com",))
    assert sender.send(message) == "abc"
    call = client.calls[0]
    assert call["FromEmailAddress"] == "Comunicaciones OLO <comunicaciones@ologistics.com>"
    assert call["Destination"] == {"ToAddresses": ["j@x.com"], "CcAddresses": ["c@x.com"]}
    body = call["Content"]["Simple"]["Body"]
    assert body["Text"] == {"Data": "Cuerpo", "Charset": "UTF-8"}
    assert body["Html"] == {"Data": "<div>Cuerpo</div>", "Charset": "UTF-8"}


def test_ses_sender_omits_cc_when_empty():
    client = _Recorder({})
    SesEmailSender("c@ologistics.com", client=client).send(EmailMessage("j@x.com", "s", "t", "h"))
    assert client.calls[0]["Destination"] == {"ToAddresses": ["j@x.com"]}
