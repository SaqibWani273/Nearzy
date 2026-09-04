'use strict';

const { ProductCategory } = require('../models');
const gemini = require('../config/gemini');

/**
 * Turning a photograph of a product into a draft listing.
 *
 * This exists because of the one objection every shopkeeper raises: listing
 * stock takes too long. Typing a name, a brand, two descriptions and an item
 * code per product is days of unpaid work for a shop with a few hundred lines,
 * and it is the usual reason a marketplace never gets any supply. A photo of
 * the packet already contains most of those fields.
 *
 * **The price is deliberately not extracted.** A wrong name is a nuisance the
 * owner corrects in a second; a wrong price costs them money on a real sale and
 * loses the shop. Nothing here guesses at money — the owner types it. That
 * asymmetry is the whole safety model, so if a future version reads a printed
 * MRP it must land in a field the owner still has to confirm, never in the
 * price itself.
 *
 * The model is reached through one function (`extractFromImage`) so swapping
 * providers, or running two side by side to compare, is a config change rather
 * than a rewrite of this file.
 */

/**
 * How long to wait on the model before giving up.
 *
 * Measured against Google AI Studio's free tier, the same request came back in
 * 14 s once and was still running past 90 s another time — free-tier capacity
 * is not something to design a counter-side interaction around. Without a
 * ceiling the request simply hangs, so the shopkeeper is left holding a phone
 * that appears frozen with no way back to typing.
 *
 * A fast, honest "fill it in yourself" beats an indefinite spinner.
 */
const EXTRACTION_TIMEOUT_MS = Number(process.env.GEMINI_TIMEOUT_MS || 25000);

const TIMED_OUT = {
  error: 'Reading the photo took too long. Fill the form in by hand.',
  code: 'DRAFT_TIMEOUT',
  status: 504,
};

const NOT_CONFIGURED = {
  error: 'Listing assistant not configured. Set GEMINI_API_KEY.',
  code: 'DRAFT_UNAVAILABLE',
  status: 503,
};

/** How sure the model is about a field, so the app can flag what to check. */
const CONFIDENCE = ['high', 'medium', 'low'];

/**
 * JSON Schema for the draft. Passed to the model as the response contract and
 * used to shape what we hand back.
 *
 * `categoryId` is an enum of this deployment's real category ids rather than a
 * free integer — a model asked for "a category id" will happily invent one,
 * and an invented id fails the foreign key at create time with an error the
 * shopkeeper cannot act on.
 */
function draftSchema(categoryIds) {
  return {
    type: 'object',
    properties: {
      name: { type: 'string', description: 'Product name as printed on the packaging' },
      brand: { type: 'string', description: 'Brand name, or empty string if unbranded' },
      size: {
        type: 'string',
        description: 'Net quantity as printed, e.g. "500 g", "1 L". Empty if absent.',
      },
      categoryId: {
        type: 'integer',
        enum: categoryIds,
        description: 'The single best-fitting category id from the list',
      },
      shortDescription: {
        type: 'string',
        description: 'One plain sentence a shopper would see in a list',
      },
      completeDescription: {
        type: 'string',
        description: 'Two or three sentences for the product page',
      },
      confidence: {
        type: 'object',
        description: 'How legible each field was in the photo',
        properties: {
          name: { type: 'string', enum: CONFIDENCE },
          brand: { type: 'string', enum: CONFIDENCE },
          size: { type: 'string', enum: CONFIDENCE },
          categoryId: { type: 'string', enum: CONFIDENCE },
        },
        required: ['name', 'brand', 'size', 'categoryId'],
      },
    },
    required: ['name', 'brand', 'size', 'categoryId', 'shortDescription', 'completeDescription', 'confidence'],
  };
}

function buildPrompt(categories) {
  const list = categories.map((c) => `${c.id} = ${c.name}`).join('\n');
  return [
    'You are helping a small shop owner in India list a product for sale.',
    'Read the photograph and fill in what the packaging actually says.',
    '',
    'Rules:',
    '- Transcribe the name and brand from the packaging. Do not translate them.',
    '- If something is not legible or not present, use an empty string and mark',
    '  that field\'s confidence "low". Never invent a brand or a size.',
    '- Do not state or guess a price, an MRP, or any amount of money anywhere,',
    '  including inside the descriptions.',
    '- Descriptions should be plain and factual, the way a shopkeeper would',
    '  describe the item. No marketing language.',
    '- Pick exactly one categoryId from this list:',
    list,
  ].join('\n');
}

/**
 * One model call. The only provider-specific code in this file.
 *
 * @param {{url?: string, base64?: string, mimeType?: string}} image
 * @param {string} prompt
 * @param {object} schema JSON Schema the response must satisfy.
 * @returns {Promise<string>} Raw JSON text.
 */
async function extractFromImage(image, prompt, schema) {
  const client = gemini.getClient();

  // Cloudinary already holds the photo by the time a product is saved, so a URL
  // is the normal path and base64 is the fallback for anything not uploaded yet.
  const imagePart = image.url
    ? { type: 'image', uri: image.url, mime_type: image.mimeType || 'image/jpeg' }
    : { type: 'image', data: image.base64, mime_type: image.mimeType || 'image/jpeg' };

  // Raced rather than cancelled: the SDK gives no abort handle here, so the
  // losing request is abandoned. That wastes one provider call at worst, which
  // is the right trade against a request that never returns.
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error('EXTRACTION_TIMEOUT')), EXTRACTION_TIMEOUT_MS);
  });

  try {
    const interaction = await Promise.race([
      client.interactions.create({
        model: gemini.getModel(),
        input: [{ type: 'text', text: prompt }, imagePart],
        response_format: {
          type: 'text',
          mime_type: 'application/json',
          schema,
        },
      }),
      timeout,
    ]);

    return interaction.output_text;
  } finally {
    clearTimeout(timer);
  }
}

const listingDraftService = {
  isAvailable: () => gemini.isConfigured(),

  /**
   * Reads a product photo and returns fields for the owner to confirm.
   *
   * Never creates anything: the draft goes back to the app, the owner corrects
   * what is wrong and adds the price, and `POST /shop/add-product` does the
   * writing. A model that can both read a photo and insert a row is one bad
   * extraction away from a catalogue full of confident nonsense.
   */
  async draftFromImage({ imageUrl, imageBase64, mimeType } = {}) {
    if (!gemini.isConfigured()) return NOT_CONFIGURED;

    if (!imageUrl && !imageBase64) {
      return { error: 'Provide imageUrl or imageBase64', status: 400 };
    }

    const categories = await ProductCategory.findAll({
      attributes: ['id', 'name'],
      order: [['display_order', 'ASC']],
    });
    if (categories.length === 0) {
      return { error: 'No product categories exist yet', status: 409 };
    }

    const schema = draftSchema(categories.map((c) => c.id));

    let raw;
    try {
      raw = await extractFromImage(
        { url: imageUrl, base64: imageBase64, mimeType },
        buildPrompt(categories),
        schema
      );
    } catch (err) {
      // The form still works by hand, so a provider outage is a degraded
      // feature and not a failed upload.
      if (err.message === 'EXTRACTION_TIMEOUT') {
        console.error(`[listingDraft] timed out after ${EXTRACTION_TIMEOUT_MS}ms`);
        return TIMED_OUT;
      }
      console.error('[listingDraft] extraction failed:', err.message);
      return {
        error: 'Could not read that photo. Fill the form in by hand.',
        code: 'DRAFT_FAILED',
        status: 502,
      };
    }

    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      console.error('[listingDraft] model returned non-JSON');
      return {
        error: 'Could not read that photo. Fill the form in by hand.',
        code: 'DRAFT_FAILED',
        status: 502,
      };
    }

    const validIds = new Set(categories.map((c) => c.id));
    const categoryId = validIds.has(parsed.categoryId) ? parsed.categoryId : null;

    const text = (value) => (typeof value === 'string' ? value.trim() : '');

    // The size belongs in the name a shopper reads — "Butter 500 g" is what is
    // on the shelf — but only when the packet actually stated one.
    const name = text(parsed.name);
    const size = text(parsed.size);

    return {
      draft: {
        name: size && !name.toLowerCase().includes(size.toLowerCase())
          ? `${name} ${size}`.trim()
          : name,
        brand: text(parsed.brand),
        size,
        categoryId,
        shortDescription: text(parsed.shortDescription),
        completeDescription: text(parsed.completeDescription),
        // Stated so no client can mistake an absent price for a free product.
        priceInPaise: null,
      },
      confidence: parsed.confidence || {},
      // Surfaced rather than silently dropped: the app should make the owner
      // pick a category when the model could not.
      needsAttention: [
        ...(categoryId === null ? ['categoryId'] : []),
        ...Object.entries(parsed.confidence || {})
          .filter(([, level]) => level === 'low')
          .map(([field]) => field),
      ],
      model: gemini.getModel(),
    };
  },
};

module.exports = listingDraftService;
