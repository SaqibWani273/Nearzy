'use strict';

const { toShopDto } = require('./productDto');

/**
 * ShopVerification (+ shop, user, locationInfo) -> the admin review feed's card.
 *
 * The admin screen needs two things the customer-facing `toShopDto` does not
 * carry on its own: the *decision state* (who judged it and when), and the
 * document URLs presented as a reviewable list rather than as loose fields.
 * Everything the reviewer looks at is here, so the client renders a card from
 * one object.
 */

const str = (v) => (v == null ? '' : String(v));

function toVerificationDto(verification) {
  if (!verification) return null;

  const shop = verification.shop;

  // Only documents that actually exist. A card that renders four slots, two of
  // them broken, reads as a failed load rather than as "this applicant
  // supplied two documents".
  const documents = [
    { label: 'PAN card', url: str(verification.pancardPicUrl) },
    { label: 'Owner ID', url: str(verification.ownerIdPicUrl) },
    { label: 'Business licence', url: str(verification.businessLicense) },
    { label: 'Owner photo', url: str(verification.ownerPicUrl) },
  ].filter((doc) => doc.url !== '');

  return {
    id: verification.id ?? null,
    shopId: verification.shopId ?? null,
    ownerName: str(verification.ownerName),
    status: str(verification.status),
    submittedAt: verification.submittedAt ?? null,
    verifiedAt: verification.verifiedAt ?? null,
    verifiedByAdminId: verification.verifiedByAdminId ?? null,
    documents,
    // The full shop card, so the reviewer sees the trading name, address and
    // location they are judging without a second request.
    //
    // `toShopDto` derives `isVerified` from a nested `verification` association
    // that this query does not load — it would be re-fetching the row we are
    // already holding — so the flag is restated from the record in hand rather
    // than left reading false for every approved shop.
    shop: shop
      ? { ...toShopDto(shop), isVerified: verification.status === 'APPROVED' }
      : null,
  };
}

module.exports = { toVerificationDto };
