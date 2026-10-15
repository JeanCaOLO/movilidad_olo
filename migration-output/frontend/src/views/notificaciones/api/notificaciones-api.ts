/** Envío de correos del sistema (antes Edge Function send-eval-email). */
import { axiosApiGateway } from '../../../shared/api/axios-api-gateway';

export interface EvaluationEmail {
  to: string;
  subject: string;
  body: string;
  cc?: string;
}

export const notificacionesApi = {
  async sendEvaluationEmail(email: EvaluationEmail): Promise<{ ok: boolean; id?: string }> {
    const { data } = await axiosApiGateway.post('/notifications/evaluation-emails', email);
    return data;
  },
};
