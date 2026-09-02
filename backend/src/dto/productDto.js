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

/**
 * Great-circle distance in km between two lat-lng points.
 *
 * Mirrors the Haversine expression used in the SQL radius filter so the
 * number the client renders agrees with the set of rows it was sent.
 */
function haversineKm(lat1, lng1, lat2, lng2) {
  if ([lat1, lng1, lat2, lng2].some((v) => v == null || Number.isNaN(Number(v)))) {
    return null;
  }
  const toRad = (d) => (Number(d) * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.min(1, Math.sqrt(a)));
}

/**
 * Shop (+ user, locationInfo, verification, categories) -> ShopModel1
 *
 * `origin` is the point the customer is browsing from. When supplied, the
 * shop carries a `distanceKm` so the client can render "1.2 km away" and
 * sort without a second round trip.
 */
function toShopDto(shop, origin = null) {
  const verification = shop?.verification;
  const location = shop?.locationInfo;

  const distanceKm =
    origin && location
      ? haversineKm(origin.latitude, origin.longitude, location.latitude, location.longitude)
      : null;

  return {
    id: shop?.id ?? null,
    user: toBasicUserDto(shop?.user),
    description: str(shop?.description),
    categories: (shop?.categories ?? []).map((c) => str(c?.name)),
    ownerPicUrl: str(verification?.ownerPicUrl),
    locationInfo: toLocationDto(location),
    ownerName: str(verification?.ownerName),
    shopPicUrl: str(shop?.shopPicUrl),
    pancardPicUrl: str(verification?.pancardPicUrl),
    ownerIdPicUrl: str(verification?.ownerIdPicUrl),
    businessLicense: str(verification?.businessLicense),
    address: str(shop?.address),
    phoneNumber: str(shop?.phoneNumber),

    // ── Discovery fields ────────────────────────────────────────────────
    // The shop's own trading name. The client previously fell back to
    // `user.username`, which is a login handle, not a shop name.
    name: str(shop?.name),
    slug: str(shop?.slug),
    isVerified: verification?.status === 'APPROVED' || Boolean(verification?.isVerified),
    distanceKm: distanceKm == null ? null : Number(distanceKm.toFixed(2)),
    productCount: shop?.products?.length ?? null,
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

/**
 * Customer -> the client's `Customer.fromMap` shape.
 *
 * The client reads the nested user from `myUser` and a flat `cartItems` list,
 * neither of which matches the raw Sequelize entity (`user`, `cart.items`) the
 * profile endpoints used to return — so `Customer.fromMap` threw on a null
 * cast and every sign-in failed after the token check passed. Orders are left
 * off deliberately: the client loads them from its own endpoint and treats a
 * missing key as "not loaded yet".
 */
function toCustomerDto(customer) {
  const items = customer?.cart?.items ?? [];

  return {
    id: customer?.id ?? null,
    myUser: toBasicUserDto(customer?.user),
    cartItems: items.map((item) => ({
      productId: numOr(item?.productId),
      quantity: numOr(item?.quantity, 1),
    })),
  };
}

module.exports = {
  haversineKm,
  toProductDto,
  toShopDto,
  toCategoryDto,
  toLocationDto,
  toBasicUserDto,
  toCustomerDto,
};
