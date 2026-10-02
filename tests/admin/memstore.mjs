// In-memory version of functions/_lib/admin_store.js for the offline admin
// tests. Dates are kept as ISO strings (what the REST store reads back).
import { newId } from '../../functions/_lib/admin_store.js';

const norm = (v) => (v instanceof Date ? v.toISOString() : Array.isArray(v) ? v.map(norm) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, norm(x)])) : v);
const clone = (v) => (v == null ? v : JSON.parse(JSON.stringify(v)));
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

export function memStore(seed = {}, clock = { t: Date.UTC(2026, 9, 2, 12) }) {
  const store = new Map(Object.entries(seed).map(([k, v]) => [k, norm(v)]));
  const test = (data, [f, op, raw]) => {
    const v = data[f];
    const w = norm(raw);
    if (v === undefined) return false;
    switch (op) {
      case '==': return JSON.stringify(v) === JSON.stringify(w);
      case '<': return v < w;
      case '<=': return v <= w;
      case '>': return v > w;
      case '>=': return v >= w;
      case 'array-contains': return Array.isArray(v) && v.includes(w);
      case 'in': return w.includes(v);
      default: return false;
    }
  };
  const rows = ({ parent = '', collection, where = [] }) => {
    const out = [];
    for (const [path, data] of store) {
      const parts = path.split('/');
      if (parts.length % 2) continue;
      if (parts[parts.length - 2] !== collection || parts.slice(0, -2).join('/') !== parent) continue;
      if (!where.every((c) => test(data, c))) continue;
      out.push({ id: parts[parts.length - 1], path, data: clone(data) });
    }
    return out;
  };
  const apply = (ops) => {
    for (const o of ops) if (o.op === 'create' && store.has(o.path)) throw new Error('ALREADY_EXISTS ' + o.path);
    for (const o of ops) {
      if (o.op === 'delete') { store.delete(o.path); continue; }
      const data = norm(clone({ ...(o.data || {}) }));
      for (const f of o.serverTime || []) data[f] = new Date(clock.t).toISOString();
      if (o.op === 'merge') store.set(o.path, { ...(store.get(o.path) || {}), ...data });
      else store.set(o.path, data);
    }
  };
  return {
    store,
    clock,
    newId,
    async get(p) { return clone(store.get(p) ?? null); },
    async getMany(paths) { return new Map(paths.map((p) => [p, clone(store.get(p) ?? null)])); },
    async query(o) {
      let r = rows(o);
      if (o.orderBy && o.orderBy.length) {
        const [f, dir] = o.orderBy[0];
        r = r.filter((x) => x.data[f] !== undefined).sort((a, b) => cmp(a.data[f], b.data[f]) * (dir === 'desc' ? -1 : 1));
        if (o.startAfter && o.startAfter.length) r = r.filter((x) => (dir === 'desc' ? x.data[f] < o.startAfter[0] : x.data[f] > o.startAfter[0]));
      }
      return r.slice(0, o.limit || 1000);
    },
    async count(o) { return rows(o).length; },
    async sum(o) { return rows(o).reduce((s, x) => s + (Number(x.data[o.field]) || 0), 0); },
    async commit(ops) { apply(ops); return { ok: true }; },
    async runTransaction(fn) {
      const ops = [];
      const tx = {
        get: async (p) => clone(store.get(p) ?? null),
        set: (path, data, o = {}) => ops.push({ op: o.merge ? 'merge' : 'set', path, data }),
        create: (path, data) => ops.push({ op: 'create', path, data }),
        delete: (path) => ops.push({ op: 'delete', path }),
      };
      const out = await fn(tx);
      apply(ops);
      return out;
    },
  };
}
