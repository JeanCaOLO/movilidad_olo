/**
 * Controller de envío de correo: misma validación y mismos errores que sendMailNow() original.
 * Remitente: el del sistema (comunicaciones@ologistics.com), configurado en el backend.
 */
import { notificacionesApi, type EvaluationEmail } from '../api/notificaciones-api';

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export interface EmailSenderController {
  sendMailNow(to: string, subject: string, body: string, cc?: string): Promise<boolean>;
}

export function useEmailSenderController(): EmailSenderController {
  return {
    async sendMailNow(to, subject, body, cc) {
      const target = String(to || '').trim();
      if (!EMAIL_RE.test(target)) throw new Error('Correo inválido: ' + (to || '(vacío)'));
      const payload: EvaluationEmail = { to: target, subject, body };
      if (cc && /@/.test(cc)) payload.cc = String(cc).trim();
      await notificacionesApi.sendEvaluationEmail(payload);
      return true;
    },
  };
}
