const Razorpay = require('razorpay');

let client = null;

const getKeyId = () => process.env.RAZORPAY_KEY_ID || '';
const getKeySecret = () => process.env.RAZORPAY_KEY_SECRET || '';

/**
 * Both credentials live on the server only. The key id is safe to hand to the
 * app (the checkout SDK needs it); the key secret never leaves this process.
 */
const isConfigured = () => Boolean(getKeyId() && getKeySecret());

/**
 * Built on first use rather than at import time, so the server still boots
 * while the credentials are placeholders. Callers must check isConfigured().
 */
const getClient = () => {
  if (!isConfigured()) return null;
  if (!client) {
    client = new Razorpay({ key_id: getKeyId(), key_secret: getKeySecret() });
  }
  return client;
};

module.exports = { getClient, getKeyId, getKeySecret, isConfigured };
