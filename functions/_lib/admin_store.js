/* Firestore REST for the admin console (functions/api/admin/[action].js).

   One small interface, two implementations: this one (REST, service
   account) and tests/admin/memstore.mjs (in memory, for the offline tests).

     get(path)                         → plain object | null
     getMany(paths)                    → Map(path → object|null)   (batchGet)
     query({ parent, collection, where, orderBy, limit, select, startAfter })
                                       → [{ id, path, data }]
     count({ parent, collection, where })        → number
     sum({ parent, collection, where, field })   → number
     commit(ops)                       → writes in one atomic commit
     runTransaction(async (tx) => …)   → tx.get(path), tx.set/create/delete
     newId()

   An op is { op: 'set'|'merge'|'create'|'delete', path, data, serverTime: [fields] }.
   'merge' only touches the top-level keys in data. Dates become Firestore
   timestamps; timestamps read back as ISO strings. */
import { fsFields, fsPlain, fsValue } from './server.js';

const OPS = {
  '==': 'EQUAL', '!=': 'NOT_EQUAL', '<': 'LESS_THAN', '<=': 'LESS_THAN_OR_EQUAL', '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL', 'array-contains': 'ARRAY_CONTAINS', in: 'IN',
};

export function newId() {
  const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const b = crypto.getRandomValues(new Uint8Array(20));
  let s = '';
  for (const x of b) s += abc[x % abc.length];
  return s;
}

const fieldPath = (f) => String(f).split('.').map((p) => (/^[A-Za-z_][A-Za-z_0-9]*$/.test(p) ? p : '`' + p.replace(/`/g, '\\`') + '`')).join('.');

export function encodeWhere(where) {
  const filters = (where || []).map(([field, op, value]) => ({
    fieldFilter: { field: { fieldPath: fieldPath(field) }, op: OPS[op] || 'EQUAL', value: fsValue(value) },
  }));
  if (!filters.length) return undefined;
  if (filters.length === 1) return filters[0];
  return { compositeFilter: { op: 'AND', filters } };
}

export function structuredQuery({ collection, where, orderBy, limit, select, startAfter }) {
  const q = { from: [{ collectionId: collection }] };
  const w = encodeWhere(where);
  if (w) q.where = w;
  if (orderBy && orderBy.length) {
    q.orderBy = orderBy.map(([f, dir]) => ({ field: { fieldPath: fieldPath(f) }, direction: dir === 'desc' ? 'DESCENDING' : 'ASCENDING' }));
    if (startAfter && startAfter.length) q.startAt = { values: startAfter.map(fsValue), before: false };
  }
  if (select) q.select = { fields: select.map((f) => ({ fieldPath: fieldPath(f) })) };
  if (limit) q.limit = limit;
  return q;
}

export function encodeOps(base, ops) {
  return ops.map((o) => {
    const name = `${base}/${o.path}`;
    if (o.op === 'delete') return { delete: name };
    const data = o.data || {};
    const st = o.serverTime || [];
    const plain = Object.fromEntries(Object.entries(data).filter(([k]) => !st.includes(k)));
    const w = { update: { name, fields: fsFields(plain) } };
    if (o.op === 'merge') w.updateMask = { fieldPaths: Object.keys(plain).map(fieldPath) };
    if (o.op === 'create') w.currentDocument = { exists: false };
    if (st.length) w.updateTransforms = st.map((f) => ({ fieldPath: fieldPath(f), setToServerValue: 'REQUEST_TIME' }));
    return w;
  });
}

export function restStore(token, project, fetchImpl = (...a) => fetch(...a)) {
  const root = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
  const base = `projects/${project}/databases/(default)/documents`;
  const headers = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' };
  const encPath = (p) => p.split('/').map(encodeURIComponent).join('/');
  const post = async (url, body, what) => {
    const r = await fetchImpl(url, { method: 'POST', headers, body: JSON.stringify(body) });
    if (!r.ok) {
      const t = await r.text().catch(() => '');
      const e = new Error(`firestore ${what} ${r.status}`);
      e.status = r.status;
      e.detail = t.slice(0, 300);
      throw e;
    }
    return r.json();
  };

  async function get(path, transaction) {
    const q = transaction ? '?transaction=' + encodeURIComponent(transaction) : '';
    const r = await fetchImpl(`${root}/${encPath(path)}${q}`, { headers });
    if (r.status === 404) return null;
    if (!r.ok) throw new Error('firestore get ' + r.status);
    const d = await r.json();
    return fsPlain({ mapValue: { fields: d.fields || {} } });
  }

  async function getMany(paths, transaction) {
    const out = new Map();
    const list = [...new Set(paths)];
    for (let i = 0; i < list.length; i += 100) {
      const chunk = list.slice(i, i + 100);
      const body = { documents: chunk.map((p) => `${base}/${p}`) };
      if (transaction) body.transaction = transaction;
      const rows = await post(`${root}:batchGet`, body, 'batchGet');
      for (const row of rows || []) {
        if (row.found) {
          const p = row.found.name.slice(row.found.name.indexOf('/documents/') + 11);
          out.set(p, fsPlain({ mapValue: { fields: row.found.fields || {} } }));
        } else if (row.missing) {
          out.set(row.missing.slice(row.missing.indexOf('/documents/') + 11), null);
        }
      }
    }
    for (const p of list) if (!out.has(p)) out.set(p, null);
    return out;
  }

  async function query(opts) {
    const url = opts.parent ? `${root}/${encPath(opts.parent)}:runQuery` : `${root}:runQuery`;
    const rows = await post(url, { structuredQuery: structuredQuery(opts) }, 'query');
    return (rows || []).filter((x) => x.document).map((x) => ({
      id: x.document.name.split('/').pop(),
      path: x.document.name.slice(x.document.name.indexOf('/documents/') + 11),
      data: fsPlain({ mapValue: { fields: x.document.fields || {} } }),
    }));
  }

  async function aggregate(opts, aggregation) {
    const url = opts.parent ? `${root}/${encPath(opts.parent)}:runAggregationQuery` : `${root}:runAggregationQuery`;
    const sq = structuredQuery({ collection: opts.collection, where: opts.where });
    const rows = await post(url, { structuredAggregationQuery: { structuredQuery: sq, aggregations: [{ alias: 'v', ...aggregation }] } }, 'aggregate');
    const f = rows && rows[0] && rows[0].result && rows[0].result.aggregateFields && rows[0].result.aggregateFields.v;
    const v = fsPlain(f);
    return Number.isFinite(Number(v)) ? Number(v) : 0;
  }
  const count = (opts) => aggregate(opts, { count: {} });
  const sum = (opts) => aggregate(opts, { sum: { field: { fieldPath: fieldPath(opts.field) } } });

  async function commit(ops, transaction) {
    if (!ops.length) return { ok: true };
    const body = { writes: encodeOps(base, ops) };
    if (transaction) body.transaction = transaction;
    await post(`${root}:commit`, body, 'commit');
    return { ok: true };
  }

  async function runTransaction(fn, attempts = 4) {
    let last;
    for (let i = 0; i < attempts; i++) {
      const { transaction } = await post(`${root}:beginTransaction`, { options: { readWrite: {} } }, 'begin');
      const ops = [];
      const tx = {
        get: (p) => get(p, transaction),
        set: (path, data, o = {}) => ops.push({ op: o.merge ? 'merge' : 'set', path, data, serverTime: o.serverTime }),
        create: (path, data, o = {}) => ops.push({ op: 'create', path, data, serverTime: o.serverTime }),
        delete: (path) => ops.push({ op: 'delete', path }),
      };
      let result;
      try {
        result = await fn(tx);
      } catch (e) {
        await fetchImpl(`${root}:rollback`, { method: 'POST', headers, body: JSON.stringify({ transaction }) }).catch(() => {});
        throw e;
      }
      try {
        if (ops.length) await commit(ops, transaction);
        else await fetchImpl(`${root}:rollback`, { method: 'POST', headers, body: JSON.stringify({ transaction }) }).catch(() => {});
        return result;
      } catch (e) {
        last = e;
        if (e.status === 409 || /ABORTED/.test(e.detail || '')) continue;
        throw e;
      }
    }
    throw last || new Error('firestore transaction failed');
  }

  return { get: (p) => get(p), getMany: (p) => getMany(p), query, count, sum, commit: (ops) => commit(ops), runTransaction, newId };
}
