'use strict';

/**
 * Maps Sequelize entities to the JSON shapes the Flutter client expects.
 *
 * The client's json_serializable models are generated with non-nullable casts
 * (`json['brand'] as String`) for several columns that are nullable in the
 * database, so every such field is coalesced to a safe default here. Returning
 * raw ORM entities also leaked internal column names (priceInPaise, avgRating)
 * and the password hash, which is why this layer exists at all.
 */

const str = (v) => (v == null ? '' : String(v));
const numOr = (v, fallback = 0) => (v == null ? fallback : Number(v));
const numOrNull = (v) => (v == null ? null : Number(v));

/** NearzyUser -> BasicUserModel */
function toBasicUserDto(user) {
  return {
    id: user?.id ?? null,
    username: str(user?.username),
    // The client model declares `password` non-nullable, but the password hash
    // must never leave the server. Send an empty placeholder instead.
    password: '',
    email: str(user?.email),
  };
}

/** LocationInfo -> client LocationInfo. Note the client's field is misspelled. */
function toLocationDto(loc) {
  return {
    completeAddress: str(loc?.completeAddress),
    shortAddress: str(loc?.shortAddress),
    latitude: numOr(loc?.latitude),
    longtitude: numOr(loc?.longitude),
  };
}

/** ProductCategory -> GeneralSpecificCategory */
function toCategoryDto(category) {
  return {
    name: str(category?.name),
    // Nullable on the client; the JSON columns already carry the
    // stringAttributes/boolAttributes/enumAttributes shape it parses.
    mustHaveSpecificAttributes: category?.requiredAttributes ?? null,
    canHaveSpecificAttributes: category?.optionalAttributes ?? null,
  };
}

/** Shop (+ user, locationInfo, verification, categories) -> ShopModel1 */
function toShopDto(shop) {
  const verification = shop?.verification;
  return {
    id: shop?.id ?? null,
    user: toBasicUserDto(shop?.user),
    description: str(shop?.description),
    categories: (shop?.categories ?? []).map((c) => str(c?.name)),
    ownerPicUrl: str(verification?.ownerPicUrl),
    locationInfo: toLocationDto(shop?.locationInfo),
    ownerName: str(verification?.ownerName),
    shopPicUrl: str(shop?.shopPicUrl),
    pancardPicUrl: str(verification?.pancardPicUrl),
    ownerIdPicUrl: str(verification?.ownerIdPicUrl),
    businessLicense: str(verification?.businessLicense),
    address: str(shop?.address),
    phoneNumber: str(shop?.phoneNumber),
  };
}

/** Product (+ shop, category, images, colors) -> client Product */
function toProductDto(product) {
  const images = [...(product?.images ?? [])]
    .sort((a, b) => (a?.displayOrder ?? 0) - (b?.displayOrder ?? 0))
    .map((image) => str(image?.url));

  return {
    id: product?.id ?? null,
    name: str(product?.name),
    brand: str(product?.brand),
    shortDescription: str(product?.shortDescription),
    images,
    // The client stores paise in a field it simply calls `price`; its UI
    // divides by 100 at render time, so no unit conversion belongs here.
    price: numOr(product?.priceInPaise),
    discountInPercentage: numOrNull(product?.discountPercent),
    completeDescription: str(product?.completeDescription),
    shop: toShopDto(product?.shop),
    stockQuantity: numOr(product?.stockQuantity),
    rating: numOrNull(product?.avgRating),
    category: toCategoryDto(product?.category),
    colors: (product?.colors ?? []).map((c) => str(c?.colorName)),
    available: Boolean(product?.available),
    sku: str(product?.sku),
  };
}

module.exports = {
  toProductDto,
  toShopDto,
  toCategoryDto,
  toLocationDto,
  toBasicUserDto,
};
