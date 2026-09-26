const { HttpsError } = require('firebase-functions/v2/https');

const PACKAGE = process.env.PLAY_PACKAGE_NAME || 'com.nowssb.app';

/**
 * Confirms a Google Play product purchase. Fails closed when the service
 * account is not configured — the client receipt is never trusted on its own.
 */
async function verifyPlayProduct(productId, token) {
  if (!token || String(token).length < 8) {
    throw new HttpsError('invalid-argument', 'Missing Play purchase token.');
  }
  const raw = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new HttpsError(
      'failed-precondition',
      'Play Billing verification is not configured. Set PLAY_SERVICE_ACCOUNT_JSON on the Cloud Functions service.',
    );
  }
  let credentials;
  try {
    credentials = JSON.parse(raw);
  } catch (_) {
    throw new HttpsError('failed-precondition', 'PLAY_SERVICE_ACCOUNT_JSON is not valid JSON.');
  }
  const { google } = require('googleapis');
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const publisher = google.androidpublisher({ version: 'v3', auth });
  const res = await publisher.purchases.products.get({
    packageName: PACKAGE,
    productId,
    token,
  });
  const data = res.data || {};
  if (Number(data.purchaseState) !== 0) {
    throw new HttpsError('failed-precondition', 'Play has not completed this purchase.');
  }
  return {
    orderId: data.orderId || '',
    productId,
    purchaseTime: Number(data.purchaseTimeMillis || 0),
  };
}

module.exports = { verifyPlayProduct, PACKAGE };
