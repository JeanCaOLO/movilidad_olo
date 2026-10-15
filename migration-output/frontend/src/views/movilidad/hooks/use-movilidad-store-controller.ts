/**
 * Controller del almacén de movilidad: conserva la API del objeto `Store` original
 * (list, getAll, get, set, del) con su caché en memoria y sus mensajes de error.
 * Las lecturas masivas se cancelan con AbortController si se llama a abort().
 */
import type { ApiError } from '../../../shared/api/api-error';
import { movilidadApi } from '../api/movilidad-api';

export interface MovilidadStore {
  list(prefix: string): Promise<string[]>;
  getAll(prefix: string): Promise<unknown[]>;
  get(key: string): Promise<unknown>;
  set(key: string, value: unknown): Promise<void>;
  del(key: string): Promise<void>;
  checkConnection(): Promise<void>;
  abort(): void;
}

function parse(raw: string | undefined): unknown {
  if (raw === undefined) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function useMovilidadStoreController(toast: (message: string) => void): MovilidadStore {
  const mem = new Map<string, string>();
  const loads = new Set<AbortController>();
  const memKeys = (prefix: string) => [...mem.keys()].filter((k) => k.startsWith(prefix));

  function startLoad(): AbortController {
    const controller = new AbortController();
    loads.add(controller);
    return controller;
  }

  return {
    async list(prefix) {
      const controller = startLoad();
      try {
        return await movilidadApi.listKeys(prefix, { signal: controller.signal });
      } catch (e) {
        if (!(e as ApiError).isCanceled) console.error('store list', e);
        return memKeys(prefix);
      } finally {
        loads.delete(controller);
      }
    },

    async getAll(prefix) {
      const controller = startLoad();
      try {
        const all: { key: string; value: unknown }[] = [];
        let cursor: string | null = null;
        do {
          const page = await movilidadApi.listPage(prefix, cursor, { signal: controller.signal });
          all.push(...page.items);
          cursor = page.next_cursor;
        } while (cursor);
        all.forEach((r) => mem.set(r.key, JSON.stringify(r.value)));
        return all.map((r) => r.value).filter(Boolean);
      } catch (e) {
        if (!(e as ApiError).isCanceled) console.error('store getAll', e);
        return memKeys(prefix)
          .map((k) => parse(mem.get(k)))
          .filter(Boolean);
      } finally {
        loads.delete(controller);
      }
    },

    async get(key) {
      if (mem.has(key)) {
        const cached = parse(mem.get(key));
        if (cached !== null) return cached;
      }
      try {
        const entry = await movilidadApi.get(key);
        if (entry) mem.set(key, JSON.stringify(entry.value));
        return entry ? entry.value : null;
      } catch (e) {
        console.error('store get', e);
        return parse(mem.get(key));
      }
    },

    async set(key, value) {
      mem.set(key, JSON.stringify(value));
      try {
        await movilidadApi.save(key, value);
      } catch (e) {
        console.error('store set', e);
        toast('No se pudo guardar en el servidor (se guardó localmente)');
      }
    },

    async del(key) {
      mem.delete(key);
      try {
        await movilidadApi.remove(key);
      } catch (e) {
        console.error('store del', e);
      }
    },

    async checkConnection() {
      try {
        await movilidadApi.listPage('config', null, { limit: 1 });
        console.log('✓ Conectado al servidor (movilidad)');
      } catch (e) {
        console.error('Servidor:', e);
        toast('⚠ Sin conexión con el servidor de movilidad');
      }
    },

    abort() {
      loads.forEach((c) => c.abort());
      loads.clear();
    },
  };
}
