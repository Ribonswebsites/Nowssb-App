import { readFileSync, writeFileSync } from 'node:fs';

const source = readFileSync(new URL('../worker.js', import.meta.url), 'utf8');
const code = `async () => {
  const source = ${JSON.stringify(source)};
  const boundary = '----NowssB' + Date.now();
  const metadata = {
    main_module: 'worker.js',
    compatibility_date: '2026-08-23',
    bindings: []
  };
  const body = [
    '--' + boundary,
    'Content-Disposition: form-data; name="metadata"',
    'Content-Type: application/json',
    '',
    JSON.stringify(metadata),
    '--' + boundary,
    'Content-Disposition: form-data; name="worker.js"; filename="worker.js"',
    'Content-Type: application/javascript+module',
    '',
    source,
    '--' + boundary + '--',
    ''
  ].join('\\r\\n');
  return await cloudflare.request({
    method: 'PUT',
    path: '/accounts/' + accountId + '/workers/scripts/nowssb-api',
    body,
    contentType: 'multipart/form-data; boundary=' + boundary,
    rawBody: true
  });
}`;
writeFileSync('/tmp/cloudflare-worker-upload.json', JSON.stringify({ code }));
console.log('Wrote /tmp/cloudflare-worker-upload.json');
