# Nearzy

![Frame 3_1](https://github.com/user-attachments/assets/cabf5acf-6710-41ca-97fa-fe1d53a7d837)

Nearzy is a hyperlocal marketplace. Instead of a single warehouse, the catalogue
is the shops a few streets away: customers browse and order from real nearby
stores, shop owners run their own inventory and orders, and an admin verifies
who gets to sell.

https://github.com/user-attachments/assets/499a4210-d814-45ab-989d-9cfae648e7bc

## Repository layout

```
backend/    Node.js + Express REST API (Sequelize / PostgreSQL)
frontend/   Flutter app — customer, shop owner and admin in one binary
```

## Tech stack

| Layer | What it actually uses |
|---|---|
| App | Flutter 3.44.7 (pinned via [fvm](https://fvm.app)), Dart ≥3.10, `flutter_bloc` |
| API | Node.js ≥18, Express 4, Sequelize 6 |
| Database | PostgreSQL (schema kept in sync by `sequelize.sync({ alter: true })`) |
| Auth | JWT access tokens + rotating refresh tokens, `bcryptjs` password hashing |
| Payments | Razorpay (`razorpay` server SDK, `razorpay_flutter` in the app) |
| Maps | `flutter_map` + OpenStreetMap tiles, `geolocator` / `geocoding` |
| Images | Cloudinary (unsigned upload straight from the app) |
| Mail | `nodemailer` — email confirmation on signup |
| Scheduling | `node-cron` (see [Background jobs](#background-jobs)) |
| API docs | `swagger-jsdoc` + Swagger UI at `/swagger-ui` |
| Packaging | `backend/Dockerfile` (node:18-alpine, two-stage) |

There is no migration tool: models are the source of truth and the schema is
altered to match them at boot. That is fine for development and deliberately
not something to point at a production database.

## Roles

One account table (`nearzy_users`) with three roles, and the app opens on a
different home screen for each:

- **`ROLE_CUSTOMER`** — discovery, cart, checkout, orders, saved addresses.
- **`ROLE_SHOP_OWNER`** (accepted as `SHOP` too) — dashboard, inventory,
  incoming orders. Must be approved by an admin before it can trade.
- **`ROLE_ADMIN`** — verification queue, categories, demand heatmap, stats.

## Features

**Customer** — location-based shop and product discovery (`shops-near-location`,
specialities by area), category browsing, search, affordable and discounted
feeds, cart, Razorpay checkout, order history with an active-order strip on the
dashboard, and multiple saved addresses with a default.

**Shop owner** — a triage dashboard (orders awaiting dispatch, stock problems,
verification state), product upload, single and bulk stock edits, barcode
bulk-scan restocking (`mobile_scanner`), order status transitions, and an alert
inbox fed by the background jobs.

**Admin** — swipe-through shop verification queue, product categories, platform
stats, and an order-density heatmap that shows which areas justify widening the
discovery radius.

## Background jobs

`backend/src/jobs/` runs three cron jobs, **off unless `ENABLE_JOBS=true`** —
they write shared state, so two dev instances (or `nodemon` restarting on every
save) against the same database would duplicate every alert.

| Job | Schedule | What it does |
|---|---|---|
| `replenishment` | hourly | Flags stock by *days of cover* against each item's own recent velocity, not a flat threshold. Raises `LOW_STOCK` / `STOCKOUT` alerts. |
| `markdown-sweep` | every 30 min, 15:00–21:00 | Escalates end-of-day discounts toward each product's owner-set floor. Only touches products with `markdownEnabled`. |
| `markdown-reset` | 00:05 | Restores the owner's own pricing. |

Alerts are upserted on `(shop, product, type)` among unresolved rows, so a
recurring scan refreshes one alert rather than appending a new one each hour.

## Getting started

### Backend

```bash
cd backend
cp .env.example .env      # then fill it in — see the file's comments
npm install
npm run dev               # nodemon on http://localhost:8080
```

Needs a reachable PostgreSQL database (`DB_*` in `.env`) and, for signup
confirmation mail, an SMTP host. [Mailpit](https://mailpit.axllent.org) is the
easy local option — it catches every message instead of sending it. Run it,
then set `MAIL_HOST=localhost` and `MAIL_PORT=1025` (`MAIL_PORT` defaults to
587, which Mailpit does not listen on) and read the mail at
<http://localhost:8025>.

Check it came up: `curl localhost:8080/health` reports uptime and the database
version. Browse the API at <http://localhost:8080/swagger-ui>.

**Seed demo data** (additive; refuses to run if users already exist):

```bash
node src/seed.js          # accounts, shops, categories, products, reviews
node src/seed_orders.js   # sample orders on top of the above
```

All seeded passwords are `Test@1234`.

### Frontend

```bash
cd frontend
fvm install               # first time only — installs the pinned 3.44.7
fvm flutter pub get
fvm flutter run
```

Point the app at your API by editing `baseApiUrl` in
[rest_api_const.dart](frontend/lib/constants/rest_api_const.dart) — the
`localhost:8080` line is commented out just below the default. A physical
device can't reach your laptop's `localhost`; expose the backend with
`ngrok http 8080` and use that URL instead.

See [frontend/README.md](frontend/README.md) for app structure, the design
system and tests.

## Documentation

| Document | For |
|---|---|
| [Inside Nearzy](docs/inside-nearzy.html) | Non-technical overview — features, the three user journeys, how an order flows. Written for investors, collaborators and commercial partners |
| [Engineering reference](docs/nearzy-engineering-reference.html) | The full technical reference — request pipeline, auth, API surface, data model, background jobs, sharp edges |
| [frontend/README.md](frontend/README.md) | App structure, toolchain, tests |
| [nearzy-design/SKILL.md](.claude/skills/nearzy-design/SKILL.md) | The "Local Premium" design system |

Both HTML docs are standalone — open them in a browser directly. Each is also
published as a shareable page; the URL is in a comment at the top of the file.

## API surface

Five route groups, all mounted in [app.js](backend/src/app.js):

| Prefix | Contents |
|---|---|
| `/customer` | Auth, profile, discovery, cart, payments, orders, addresses |
| `/shop` | Auth, products, bulk stock, dashboard, alerts, orders |
| `/admin` | Auth, categories, stats, demand heatmap, shop verifications |
| `/user` | Shared: `/me`, token `/refresh`, `/logout`, categories, availability checks |
| `/health` | Liveness + database check |

Authentication is applied globally but never rejects on its own — many routes
are public. `authorize(...)` guards the rest, and answers 401 with a `code`
(`TOKEN_EXPIRED` vs `TOKEN_MISSING`) so the app knows whether to refresh and
retry or drop the session.

## Tests

```bash
cd frontend && fvm flutter test
```

The backend has no test suite; it is exercised against a local database and
Swagger UI.

## Licence

See [LICENSE](LICENSE).
