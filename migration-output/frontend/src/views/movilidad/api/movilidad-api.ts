/**
 * Almacén key-value de movilidad (tabla olo_movilidad_kv del sistema original).
 * Mismo acceso que en el origen: lectura y escritura completas para jefes, gerentes y
 * administradores; el filtro por país lo aplica la interfaz.
 */
import { axiosApiGateway } from '../../../shared/api/axios-api-gateway';
import type { ApiError } from '../../../shared/api/api-error';

const BASE_PATH = '/movilidad/entries';

export interface MovilidadEntry {
  key: string;
  value: unknown;
}

export interface MovilidadPage {
  items: MovilidadEntry[];
  next_cursor: string | null;
}

interface RequestOptions {
  signal?: AbortSignal;
}

function entryPath(key: string): string {
  return `${BASE_PATH}/${encodeURIComponent(key)}`;
}

export const movilidadApi = {
  async listKeys(prefix: string, options: RequestOptions = {}) {
    const { data } = await axiosApiGateway.get<{ keys?: string[] }>(BASE_PATH, {
      params: { prefix },
      signal: options.signal,
    });
    return data.keys ?? [];
  },

  async listPage(
    prefix: string,
    cursor: string | null,
    options: RequestOptions & { limit?: number } = {},
  ): Promise<MovilidadPage> {
    const { data } = await axiosApiGateway.get<MovilidadPage>(BASE_PATH, {
      params: { prefix, values: 1, cursor: cursor ?? undefined, limit: options.limit },
      signal: options.signal,
    });
    return { items: data.items ?? [], next_cursor: data.next_cursor ?? null };
  },

  /** null si no existe (antes maybeSingle()). */
  async get(key: string, options: RequestOptions = {}) {
    try {
      const { data } = await axiosApiGateway.get<MovilidadEntry>(entryPath(key), {
        signal: options.signal,
      });
      return data;
    } catch (error) {
      if ((error as ApiError).status === 404) return null;
      throw error;
    }
  },

  async save(key: string, value: unknown): Promise<void> {
    await axiosApiGateway.put(entryPath(key), { value });
  },

  async remove(key: string): Promise<void> {
    await axiosApiGateway.delete(entryPath(key));
  },
};
