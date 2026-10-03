/* Firestore REST with real read-write transactions (WebCrypto/fetch only).

   db.get(path)                       → { exists, data, updateTime }
   db.query(collection, where, opts)  → [{ id, path, data }]
   db.tx(async (t) => { await t.get(path); t.set(path, obj, { merge }); t.create(path, obj); t.delete(path) })
     Reads inside the callback run in the transaction; writes are buffered
     and committed atomically. ABORTED / contention retries up to 5 times.

   `base` points at the emulator in tests (FIRESTORE_EMULATOR_HOST). */
import { fsFields, fsPlain, fsValue, googleToken, serviceAccount } from '../server.js';

export class TxConflict extends Error {}

export function cleanId(s, max = 300) {
  return String(s || '').replace(/[^A-Za-z0-9_.@-]/g, '_').replace(/^\.+/, '_').slice(0, max) || '_';
}

export class FsDb {
  constructor({ token, project, base }) {
    this.token = token;
    this.project = project;
    this.base = (base || 'https://firestore.googleapis.com') + '/v1';
    this.root = `projects/${project}/databases/(default)/documents`;
  }

  static async fromEnv(env) {
    const project = env.FIREBASE_PROJECT_ID;
    if (env.FIRESTORE_EMULATOR_HOST) {
      return new FsDb({ token: 'owner', project, base: 'http://' + env.FIRESTORE_EMULATOR_HOST });
    }
    const token = await googleToken(serviceAccount(env));
    return new FsDb({ token, project });
  }

  name(path) { return `${this.root}/${path}`; }

  async _fetch(url, init = {}) {
    const r = await fetch(url, {
      ...init,
      headers: { Authorization: 'Bearer ' + this.token, 'Content-Type': 'application/json', ...(init.headers || {}) },
    });
    let d = null;
    try { d = await r.json(); } catch (e) { d = null; }
    return { ok: r.ok, status: r.status, data: d };
  }

  async get(path, transaction) {
    if (transaction) {
      // Reads inside a transaction go through batchGet (also what the
      // emulator supports; a GET ?transaction= can stall there).
      const r = await this._fetch(`${this.base}/${this.root}:batchGet`, { method: 'POST', body: JSON.stringify({ documents: [this.name(path)], transaction }) });
      if (!r.ok) {
        if (r.status === 409 || r.status === 400 || r.status === 10) throw new TxConflict('read ' + r.status);
        throw new Error('firestore get ' + r.status);
      }
      const row = (r.data || []).find((x) => x.found || x.missing) || {};
      if (!row.found) return { exists: false, data: null, updateTime: null };
      return { exists: true, data: fsPlain({ mapValue: { fields: row.found.fields || {} } }), updateTime: row.found.updateTime };
    }
    const r = await this._fetch(`${this.base}/${this.name(path)}`);
    if (r.status === 404) return { exists: false, data: null, updateTime: null };
    if (!r.ok) throw new Error('firestore get ' + r.status);
    return { exists: true, data: fsPlain({ mapValue: { fields: r.data.fields || {} } }), updateTime: r.data.updateTime };
  }

  /** where: [[field, op, value], ...] with op in == < <= > >= array-contains in. */
  async query(collection, where = [], { limit = 100, parent = '', orderBy = null, transaction = null } = {}) {
    const OPS = { '==': 'EQUAL', '<': 'LESS_THAN', '<=': 'LESS_THAN_OR_EQUAL', '>': 'GREATER_THAN', '>=': 'GREATER_THAN_OR_EQUAL', 'array-contains': 'ARRAY_CONTAINS', in: 'IN' };
    const filters = where.map(([f, op, v]) => ({ fieldFilter: { field: { fieldPath: f }, op: OPS[op], value: fsValue(v) } }));
    const structuredQuery = { from: [{ collectionId: collection }], limit };
    if (filters.length === 1) structuredQuery.where = filters[0];
    else if (filters.length > 1) structuredQuery.where = { compositeFilter: { op: 'AND', filters } };
    if (orderBy) structuredQuery.orderBy = [{ field: { fieldPath: orderBy[0] }, direction: orderBy[1] === 'desc' ? 'DESCENDING' : 'ASCENDING' }];
    const body = { structuredQuery };
    if (transaction) body.transaction = transaction;
    const url = `${this.base}/${this.root}${parent ? '/' + parent : ''}:runQuery`;
    const r = await this._fetch(url, { method: 'POST', body: JSON.stringify(body) });
    if (!r.ok) throw new Error('firestore query ' + r.status);
    return (r.data || []).filter((x) => x.document).map((x) => {
      const full = x.document.name;
      const rel = full.slice(full.indexOf('/documents/') + 11);
      return { id: rel.split('/').pop(), path: rel, data: fsPlain({ mapValue: { fields: x.document.fields || {} } }) };
    });
  }

  /** COUNT() aggregation (same where syntax as query); 1 read per 1000 matches. */
  async count(collection, where = [], { parent = '' } = {}) {
    const OPS = { '==': 'EQUAL', '<': 'LESS_THAN', '<=': 'LESS_THAN_OR_EQUAL', '>': 'GREATER_THAN', '>=': 'GREATER_THAN_OR_EQUAL', 'array-contains': 'ARRAY_CONTAINS', in: 'IN' };
    const filters = where.map(([f, op, v]) => ({ fieldFilter: { field: { fieldPath: f }, op: OPS[op], value: fsValue(v) } }));
    const structuredQuery = { from: [{ collectionId: collection }] };
    if (filters.length === 1) structuredQuery.where = filters[0];
    else if (filters.length > 1) structuredQuery.where = { compositeFilter: { op: 'AND', filters } };
    const url = `${this.base}/${this.root}${parent ? '/' + parent : ''}:runAggregationQuery`;
    const r = await this._fetch(url, { method: 'POST', body: JSON.stringify({ structuredAggregationQuery: { structuredQuery, aggregations: [{ alias: 'n', count: {} }] } }) });
    if (!r.ok) throw new Error('firestore count ' + r.status);
    const row = (r.data || []).find((x) => x.result);
    return Number((row && row.result.aggregateFields && row.result.aggregateFields.n && row.result.aggregateFields.n.integerValue) || 0);
  }

  /** Writes outside a transaction (still atomic as a batch). */
  async commit(writes) {
    const r = await this._fetch(`${this.base}/${this.root}:commit`, { method: 'POST', body: JSON.stringify({ writes }) });
    if (!r.ok) throw new Error('firestore commit ' + r.status + ' ' + JSON.stringify(r.data && r.data.error && r.data.error.message || ''));
    return r.data;
  }

  write(path, obj, { merge = false, create = false } = {}) {
    const w = { update: { name: this.name(path), fields: fsFields(obj) } };
    if (merge) w.updateMask = { fieldPaths: Object.keys(obj).map(quotePath) };
    if (create) w.currentDocument = { exists: false };
    return w;
  }

  async tx(fn, { retries = 5 } = {}) {
    let lastErr = null;
    for (let attempt = 0; attempt < retries; attempt++) {
      const b = await this._fetch(`${this.base}/${this.root}:beginTransaction`, { method: 'POST', body: JSON.stringify({ options: { readWrite: {} } }) });
      if (!b.ok) throw new Error('firestore begin ' + b.status);
      const transaction = b.data.transaction;
      const writes = [];
      const reads = new Map();
      const t = {
        get: async (path) => {
          if (reads.has(path)) return reads.get(path);
          const d = await this.get(path, transaction);
          reads.set(path, d);
          return d;
        },
        query: (collection, where, opts = {}) => this.query(collection, where, { ...opts, transaction }),
        set: (path, obj, opts = {}) => { writes.push(this.write(path, obj, opts)); },
        create: (path, obj) => { writes.push(this.write(path, obj, { create: true })); },
        delete: (path) => { writes.push({ delete: this.name(path) }); },
        writes,
        transaction,
      };
      let result;
      try {
        result = await fn(t);
      } catch (e) {
        await this._fetch(`${this.base}/${this.root}:rollback`, { method: 'POST', body: JSON.stringify({ transaction }) }).catch(() => {});
        if (e instanceof TxConflict) { lastErr = e; await sleep(40 * (attempt + 1)); continue; }
        throw e;
      }
      const c = await this._fetch(`${this.base}/${this.root}:commit`, { method: 'POST', body: JSON.stringify({ writes, transaction }) });
      if (c.ok) return result;
      const status = c.data && c.data.error && c.data.error.status;
      if (c.status === 409 || status === 'ABORTED') { lastErr = new TxConflict('commit aborted'); await sleep(60 * (attempt + 1)); continue; }
      if (status === 'ALREADY_EXISTS' || status === 'FAILED_PRECONDITION') {
        const e = new Error('already');
        e.code = 'already-exists';
        throw e;
      }
      throw new Error('firestore commit ' + c.status + ' ' + (c.data && c.data.error && c.data.error.message || ''));
    }
    throw lastErr || new Error('transaction failed');
  }
}

function quotePath(k) {
  return /^[A-Za-z_][A-Za-z0-9_]*$/.test(k) ? k : '`' + k.replace(/`/g, '\\`') + '`';
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
