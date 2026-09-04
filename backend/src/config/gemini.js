const { GoogleGenAI } = require('@google/genai');

let client = null;

const getApiKey = () => process.env.GEMINI_API_KEY || '';

/**
 * Vision model used for reading a product off its own packaging.
 *
 * Overridable because model names move faster than this repo does, and because
 * the cost/quality point for "read the label on a packet" is worth re-testing
 * rather than baking in.
 */
const getModel = () => process.env.GEMINI_MODEL || 'gemini-3.8-flash';

const isConfigured = () => Boolean(getApiKey());

/**
 * Built on first use, not at import, so the server still boots without a key —
 * the same shape as `config/razorpay.js`. Callers must check isConfigured().
 */
const getClient = () => {
  if (!isConfigured()) return null;
  if (!client) {
    client = new GoogleGenAI({ apiKey: getApiKey() });
  }
  return client;
};

module.exports = { getClient, getModel, isConfigured };
